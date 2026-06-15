import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../../config/config.dart';
import '../../service/auth_service.dart';
import '../../model/request/admin_add_user_post_req.dart';

class AdminAddUserScreen extends StatefulWidget {
  const AdminAddUserScreen({super.key});

  @override
  _AdminAddUserScreenState createState() => _AdminAddUserScreenState();
}

class _AdminAddUserScreenState extends State<AdminAddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController(); // เพิ่ม Controller สำหรับอีเมล
  final TextEditingController _passwordController = TextEditingController();
  
  String selectedRole = "user"; 
  final List<String> roles = ["user", "admin"];
  bool isPasswordHidden = true;
  bool _isLoading = false; // ตัวแปรสถานะกำลังโหลด

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

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
  // 2. ฟังก์ชันอัปโหลดรูปภาพไปยัง Node.js
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
        return jsonMap['urls']['original']; 
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // ==========================================
  // 3. ฟังก์ชันบันทึกข้อมูลผู้ใช้
  // ==========================================
  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String profileUrl = "-"; 

      // ถ้ามีการเลือกรูป ให้ส่งไปอัปโหลดก่อน
      if (_selectedImage != null) {
        final uploadedUrl = await _uploadImageToBackend(_selectedImage!);
        if (uploadedUrl != null) {
          profileUrl = uploadedUrl;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("อัปโหลดรูปภาพไม่สำเร็จ", style: GoogleFonts.prompt()), backgroundColor: Colors.red),
          );
          setState(() => _isLoading = false);
          return; 
        }
      }

      // นำข้อมูลมาใส่ Model
      AdminAddUserPostReq reqData = AdminAddUserPostReq(
        uName: _nameController.text.trim(),
        uEmail: _emailController.text.trim(),
        uPassword: _passwordController.text.trim(),
        uProfile: profileUrl, 
        uRole: selectedRole,
      );

      final config = await Configuration.getConfig();
      final apiEndpoint = config['apiEndpoint'];
      final String? token = await AuthService.getToken();

      final response = await http.post(
        Uri.parse("$apiEndpoint/add-user"),
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
        body: adminAddUserPostReqToJson(reqData), 
      );

      final result = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("สร้างบัญชีผู้ใช้งานสำเร็จ", style: GoogleFonts.prompt()), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // ปิดหน้าต่าง
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? "ไม่สามารถเพิ่มผู้ใช้งานได้", style: GoogleFonts.prompt()), backgroundColor: Colors.red),
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
          "เพิ่มผู้ใช้งานใหม่",
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
              // 1. ส่วนเลือกรูปโปรไฟล์
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
                        // นำรูปที่เลือกมาแสดงผล
                        image: _selectedImage != null
                            ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                            : null,
                      ),
                      child: _selectedImage == null 
                          ? const Icon(Icons.person, size: 65, color: Color(0xFF00ACC1))
                          : null,
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

              // ⭐️ เพิ่มช่องกรอกอีเมลตรงนี้
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

              // 3. ช่องกรอกรหัสผ่าน
              _buildLabel("รหัสผ่าน"),
              TextFormField(
                controller: _passwordController,
                obscureText: isPasswordHidden,
                validator: (value) => value!.isEmpty ? 'กรุณากรอกรหัสผ่าน' : null,
                decoration: InputDecoration(
                  hintText: "กำหนดรหัสผ่านบัญชี...",
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

              // 4. ส่วนเลือกสิทธิ์การใช้งาน (Role)
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

              // 5. ปุ่มสร้างบัญชีผู้ใช้งาน
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _saveUser, // เรียกใช้ฟังก์ชันบันทึก
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "สร้างบัญชีผู้ใช้งาน",
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