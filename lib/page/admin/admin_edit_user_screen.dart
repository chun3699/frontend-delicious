import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

import '../../config/config.dart';
import '../../service/auth_service.dart';
import '../../model/request/admin_update_user_req.dart';

class AdminEditUserScreen extends StatefulWidget {
  final Map<String, dynamic> userData; // รับข้อมูลเดิมมาจากหน้าค้นหา

  const AdminEditUserScreen({super.key, required this.userData});

  @override
  _AdminEditUserScreenState createState() => _AdminEditUserScreenState();
}

class _AdminEditUserScreenState extends State<AdminEditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  
  late String selectedRole; 
  late String _currentProfileUrl; // เก็บลิงก์รูปภาพปัจจุบัน

  final List<String> roles = ["user", "admin"];
  bool isPasswordHidden = true;
  bool _isLoading = false;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // นำข้อมูลเดิมมาใส่ในฟอร์ม
    _nameController = TextEditingController(text: widget.userData['u_name'] ?? '');
    _emailController = TextEditingController(text: widget.userData['u_email'] ?? ''); // ดึงอีเมลเดิม
    _passwordController = TextEditingController(); // เว้นว่างไว้ เผื่อเปลี่ยนรหัส
    selectedRole = widget.userData['u_role'] ?? 'user';
    _currentProfileUrl = widget.userData['u_profile'] ?? '-';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ==========================================
  // 1. ฟังก์ชันเลือกรูปภาพจากแกลเลอรี
  // ==========================================
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // ==========================================
  // 2. API: สั่งลบรูปภาพเดิมออกจาก Cloudinary
  // ==========================================
  Future<void> _deleteOldImage(String oldUrl) async {
    // ถ้ารูปเดิมเป็นค่าว่าง หรือขีด (-) ไม่ต้องลบ
    if (oldUrl == "-" || oldUrl.isEmpty) return; 

    try {
      final config = await Configuration.getConfig();
      final apiEndpoint = config['apiEndpoint'];
      final String? token = await AuthService.getToken();

      final response = await http.delete(
        Uri.parse("$apiEndpoint/images/delete-image"),
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
        body: jsonEncode({"public_id": oldUrl}), // ส่ง URL เต็มไปให้ Backend จัดการสกัดชื่อไฟล์เอง
      );

      print("====== [ API RESPONSE: DELETE IMAGE ] ======");
      print("Status Code: ${response.statusCode}");
      print("============================================");
    } catch (e) {
      print("Delete Old Image Error: $e");
    }
  }

  // ==========================================
  // 3. API: อัปโหลดรูปภาพใหม่ไปที่ Node.js
  // ==========================================
  Future<String?> _uploadImageToBackend(File imageFile) async {
    try {
      final config = await Configuration.getConfig();
      final apiEndpoint = config['apiEndpoint'];
      final String? token = await AuthService.getToken();

      final url = Uri.parse("$apiEndpoint/images/upload-image"); 
      final request = http.MultipartRequest('POST', url);
      
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      final response = await request.send();
      final responseData = await response.stream.bytesToString(); 
      final jsonMap = jsonDecode(responseData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonMap['urls']['original']; // นำลิงก์ Original ไปใช้งานต่อ
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // ==========================================
  // 4. API: บันทึกการแก้ไขข้อมูลผู้ใช้
  // ==========================================
  Future<void> _updateUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String finalProfileUrl = _currentProfileUrl; // ตั้งต้นด้วยรูปเดิมก่อน

      // ถ้ามีการเลือกรูปใหม่
      if (_selectedImage != null) {
        // 4.1 สั่งลบรูปเดิมทิ้งก่อน
        _deleteOldImage(_currentProfileUrl);

        // 4.2 อัปโหลดรูปใหม่ขึ้นไป
        final uploadedUrl = await _uploadImageToBackend(_selectedImage!);
        if (uploadedUrl != null) {
          finalProfileUrl = uploadedUrl;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("อัปโหลดรูปภาพใหม่ไม่สำเร็จ", style: GoogleFonts.prompt()), backgroundColor: Colors.red),
          );
          setState(() => _isLoading = false);
          return; 
        }
      }

      final config = await Configuration.getConfig();
      final apiEndpoint = config['apiEndpoint'];
      final String? token = await AuthService.getToken();
      final uid = widget.userData['uid'];

      // ⭐️ เปลี่ยนมาใช้ Model ในการจัดเตรียมข้อมูล
      AdminUpdateUserReq reqData = AdminUpdateUserReq(
        uName: _nameController.text.trim(),
        uEmail: _emailController.text.trim(),
        uProfile: finalProfileUrl,
        uRole: selectedRole,
        // เช็คว่าถ้าช่องรหัสผ่านไม่ว่าง ให้ดึงข้อความมา แต่ถ้าว่างให้ส่งเป็น null
        uPassword: _passwordController.text.isNotEmpty ? _passwordController.text.trim() : null,
      );

      final response = await http.put(
        Uri.parse("$apiEndpoint/update/$uid"), 
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
        // ⭐️ แปลง Model เป็น JSON String ผ่านฟังก์ชัน
        body: adminUpdateUserReqToJson(reqData), 
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("อัปเดตข้อมูลผู้ใช้งานสำเร็จ", style: GoogleFonts.prompt()), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // ปิดหน้าต่างกลับไปหน้ารายชื่อ
      } else {
        final result = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? "ไม่สามารถอัปเดตข้อมูลได้", style: GoogleFonts.prompt()), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้", style: GoogleFonts.prompt()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: GoogleFonts.prompt()), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF0D47A1)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "แก้ไขข้อมูลผู้ใช้งาน",
          style: GoogleFonts.prompt(color: const Color(0xFF0D47A1), fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. ส่วนแสดง/แก้ไขรูปโปรไฟล์
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F7FA),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF1976D2), width: 2),
                      ),
                      child: ClipOval(
                        child: _selectedImage != null
                            // ถ้าเลือกรูปใหม่จากเครื่อง ให้แสดงรูปนั้น
                            ? Image.file(_selectedImage!, fit: BoxFit.cover)
                            // ถ้ายังไม่ได้เลือกใหม่ ให้แสดงรูปเดิมจาก Cloudinary
                            : (_currentProfileUrl != "-" && _currentProfileUrl.isNotEmpty)
                                ? CachedNetworkImage(
                                    imageUrl: _currentProfileUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const CircularProgressIndicator(),
                                    errorWidget: (context, url, error) => const Icon(Icons.person, size: 65, color: Color(0xFF00ACC1)),
                                  )
                                : const Icon(Icons.person, size: 65, color: Color(0xFF00ACC1)),
                      ),
                    ),
                    GestureDetector(
                      onTap: _pickImage, // เรียกฟังก์ชันเลือกรูป
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0D47A1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // 2. ช่องกรอกชื่อผู้ใช้งาน
              _buildLabel("ชื่อ-นามสกุล"),
              TextFormField(
                controller: _nameController,
                validator: (value) => value!.isEmpty ? 'กรุณากรอกชื่อ-นามสกุล' : null,
                decoration: _buildInputDecoration("ตัวอย่าง: สมชาย ใจดี", Icons.person),
              ),
              const SizedBox(height: 20),

              // 3. ช่องกรอกอีเมล
              _buildLabel("อีเมล"),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'กรุณากรอกอีเมล';
                  if (!value.contains('@')) return 'รูปแบบอีเมลไม่ถูกต้อง';
                  return null;
                },
                decoration: _buildInputDecoration("ตัวอย่าง: somchai@email.com", Icons.email),
              ),
              const SizedBox(height: 20),

              // 4. ช่องกรอกรหัสผ่าน (ปล่อยว่างได้ถ้าไม่ต้องการเปลี่ยน)
              _buildLabel("รหัสผ่านใหม่ (เว้นว่างไว้หากไม่ต้องการเปลี่ยน)"),
              TextFormField(
                controller: _passwordController,
                obscureText: isPasswordHidden,
                decoration: InputDecoration(
                  hintText: "กำหนดรหัสผ่านใหม่...",
                  hintStyle: GoogleFonts.prompt(color: Colors.grey[400], fontSize: 14),
                  filled: true,
                  fillColor: Colors.grey[50],
                  prefixIcon: const Icon(Icons.lock, color: Color(0xFF1976D2)),
                  suffixIcon: IconButton(
                    icon: Icon(isPasswordHidden ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                    onPressed: () => setState(() => isPasswordHidden = !isPasswordHidden),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00ACC1))),
                ),
              ),
              const SizedBox(height: 20),

              // 5. ส่วนเลือกสิทธิ์การใช้งาน (Role)
              _buildLabel("สิทธิ์การใช้งานระบบ (Role)"),
              Row(
                children: roles.map((role) {
                  bool isSelected = selectedRole == role;
                  return Padding(
                    padding: const EdgeInsets.only(right: 15),
                    child: ChoiceChip(
                      showCheckmark: false,
                      label: Text(
                        role.toUpperCase(),
                        style: GoogleFonts.prompt(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? const Color(0xFF00ACC1) : Colors.grey[700],
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFF00ACC1).withOpacity(0.1),
                      backgroundColor: Colors.grey[100],
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => selectedRole = role);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),

              // 6. ปุ่มบันทึกข้อมูล
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _updateUser, 
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "บันทึกการแก้ไข",
                          style: GoogleFonts.prompt(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87)),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.prompt(color: Colors.grey[400], fontSize: 14),
      filled: true,
      fillColor: Colors.grey[50],
      prefixIcon: Icon(icon, color: const Color(0xFF1976D2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00ACC1))),
    );
  }
}