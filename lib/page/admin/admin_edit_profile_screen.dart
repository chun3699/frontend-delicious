import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AdminEditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> adminData;

  const AdminEditProfileScreen({Key? key, required this.adminData}) : super(key: key);

  @override
  _AdminEditProfileScreenState createState() => _AdminEditProfileScreenState();
}

class _AdminEditProfileScreenState extends State<AdminEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _passwordController;
  
  bool isPasswordHidden = true;

  @override
  void initState() {
    super.initState();
    // ดึงข้อมูลเดิมจากหน้าโปรไฟล์มาใส่ในช่องกรอกข้อมูล
    _nameController = TextEditingController(text: widget.adminData['u_name'] ?? '');
    _passwordController = TextEditingController(); // เว้นว่างไว้เพื่อให้กรอกเฉพาะตอนต้องการเปลี่ยน
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
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
          "แก้ไขข้อมูลผู้ดูแลระบบ",
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
              // 1. ส่วนแก้ไขรูปโปรไฟล์แอดมิน
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF1976D2), width: 3),
                      ),
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: widget.adminData['u_profile'] ?? "https://cdn-icons-png.flaticon.com/512/3135/3135768.png",
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const CircularProgressIndicator(),
                          errorWidget: (context, url, error) => const Icon(Icons.admin_panel_settings, size: 60),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // TODO: เชื่อมต่อ Image Picker เพื่อเลือกรูปภาพโปรไฟล์ใหม่ของแอดมิน
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xFF00ACC1), // สี Cyan
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // 2. ช่องกรอกชื่อผู้ดูแลระบบ
              _buildLabel("ชื่อ-นามสกุลผู้ดูแลระบบ"),
              TextFormField(
                controller: _nameController,
                validator: (value) => value!.isEmpty ? 'กรุณากรอกชื่อ-นามสกุล' : null,
                decoration: _buildInputDecoration("กรอกชื่อผู้ดูแลระบบ...", Icons.person),
              ),
              const SizedBox(height: 20),

              // 3. ช่องกรอกรหัสผ่านใหม่
              _buildLabel("รหัสผ่านใหม่ (เว้นว่างไว้หากไม่ต้องการเปลี่ยน)"),
              TextFormField(
                controller: _passwordController,
                obscureText: isPasswordHidden,
                decoration: InputDecoration(
                  hintText: "กรอกรหัสผ่านใหม่เพื่อความปลอดภัย...",
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
              const SizedBox(height: 40),

              // 4. ปุ่มบันทึกการเปลี่ยนแปลงข้อมูล
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1), // สี Navy Blue
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // TODO: ส่งข้อมูลอัปเดตชื่อและรหัสผ่านไปยัง Backend Node.js
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("บันทึกการแก้ไขโปรไฟล์แอดมินสำเร็จ", style: GoogleFonts.prompt())),
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: Text(
                    "บันทึกข้อมูล",
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