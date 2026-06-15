import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../service/auth_service.dart';
import '../user/edit_profile_screen.dart';
import '../login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String userName = "กำลังโหลด...";
  String role = "";
  String profileUrl = "";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAuthData();
  }

  // ดึงข้อมูลทั้งหมดจาก AuthService
  Future<void> _loadAuthData() async {
    final String? savedName = await AuthService.getName();
    final String? savedRole = await AuthService.getRole();
    final String? savedProfile = await AuthService.getProfile();
    
    if (mounted) {
      setState(() {
        userName = savedName ?? "ผู้ใช้งาน";
        role = savedRole ?? "user";
        profileUrl = savedProfile ?? "";
        _isLoading = false;
      });
    }
  }

  // ฟังก์ชันออกจากระบบ
  Future<void> _logout() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("ออกจากระบบ", style: GoogleFonts.prompt()),
        content: Text("คุณต้องการออกจากระบบใช่หรือไม่?", style: GoogleFonts.prompt()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("ยกเลิก", style: GoogleFonts.prompt())),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text("ออกจากระบบ", style: GoogleFonts.prompt(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 50),
              // รูปโปรไฟล์และชื่อ
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF1976D2), width: 3)),
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: profileUrl,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => const Icon(Icons.person, size: 60),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(userName, style: GoogleFonts.prompt(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF0D47A1))),
                    Text("สถานะ: ${role.toUpperCase()}", style: GoogleFonts.prompt(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // เมนูจัดการ
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)]),
                child: Column(
                  children: [
                    _buildProfileMenu(
                      icon: Icons.edit_document,
                      title: "แก้ไขข้อมูลส่วนตัว",
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen())),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // ปุ่มออกจากระบบ
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity, height: 55,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFEBEE),
                        foregroundColor: Colors.red[700],
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    icon: const Icon(Icons.logout),
                    label: Text("ออกจากระบบ", style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.bold)),
                    onPressed: _logout,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileMenu({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFFE0F7FA), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: const Color(0xFF00ACC1))),
      title: Text(title, style: GoogleFonts.prompt(fontSize: 16, color: Colors.black87)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}