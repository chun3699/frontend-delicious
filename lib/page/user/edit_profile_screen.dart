import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../config/config.dart';
import '../../service/auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  File? _imageFile;
  String profileUrl = "";
  bool isPasswordHidden = true;
  bool _isLoading = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  Future<void> _loadCurrentData() async {
    final name = await AuthService.getName();
    final profile = await AuthService.getProfile();
    setState(() {
      _nameController.text = name ?? "";
      profileUrl = profile ?? "";
      _isLoading = false;
    });
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _updateProfile() async {
    final uid = await AuthService.getUid();
    final token = await AuthService.getToken();
    final config = await Configuration.getConfig();

    String finalProfileUrl = profileUrl;

    // 1. อัปโหลดรูปภาพ (ถ้ามีการเลือกรูปใหม่)
    if (_imageFile != null) {
      var request = http.MultipartRequest('POST', Uri.parse("${config['apiEndpoint']}/images/upload-image"));
      request.headers.addAll({"Authorization": "Bearer $token"});
      request.files.add(await http.MultipartFile.fromPath('image', _imageFile!.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final respData = jsonDecode(response.body);
        finalProfileUrl = respData['urls']['optimized'];
      } else {
        debugPrint("Upload Error Status: ${response.statusCode}");
        debugPrint("Upload Error Body: ${response.body}");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("อัปโหลดรูปภาพไม่สำเร็จ")));
        return;
      }
    }

    // 2. อัปเดตข้อมูลผู้ใช้
    final updateResponse = await http.put(
      Uri.parse("${config['apiEndpoint']}/update/$uid"),
      headers: {"Authorization": "Bearer $token", "Content-Type": "application/json"},
      body: jsonEncode({
        "u_name": _nameController.text,
        "u_profile": finalProfileUrl,
        if (_passwordController.text.isNotEmpty) "u_password": _passwordController.text,
      }),
    );

    if (updateResponse.statusCode == 200) {
      final role = await AuthService.getRole() ?? "user";
      // อัปเดตข้อมูลใหม่ใน AuthService
      await AuthService.saveLoginData(token!, role, uid!, _nameController.text, finalProfileUrl);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("บันทึกข้อมูลเรียบร้อย")));
      Navigator.pop(context);
    } else {
      debugPrint("Update Profile Error: ${updateResponse.body}");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("บันทึกข้อมูลไม่สำเร็จ")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF0D47A1)), onPressed: () => Navigator.pop(context)),
        title: Text("แก้ไขข้อมูลส่วนตัว", style: GoogleFonts.prompt(color: const Color(0xFF0D47A1), fontWeight: FontWeight.bold)),
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF1976D2), width: 3)),
                    child: ClipOval(
                      child: _imageFile != null 
                        ? Image.file(_imageFile!, fit: BoxFit.cover)
                        : CachedNetworkImage(imageUrl: profileUrl, fit: BoxFit.cover, errorWidget: (_,__,___) => const Icon(Icons.person, size: 60)),
                    ),
                  ),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(color: Color(0xFF00ACC1), shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 40),
            _buildTextField("ชื่อ-นามสกุล", Icons.person, _nameController),
            const SizedBox(height: 20),
            _buildTextField("รหัสผ่านใหม่ (ทิ้งไว้ถ้าไม่เปลี่ยน)", Icons.lock, _passwordController, isPassword: true),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: _updateProfile,
                child: Text("บันทึกการเปลี่ยนแปลง", style: GoogleFonts.prompt(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller, {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[800])),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword && isPasswordHidden,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF1976D2)),
            suffixIcon: isPassword ? IconButton(icon: Icon(isPasswordHidden ? Icons.visibility_off : Icons.visibility, color: Colors.grey), onPressed: () => setState(() => isPasswordHidden = !isPasswordHidden)) : null,
            filled: true, fillColor: Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }
}