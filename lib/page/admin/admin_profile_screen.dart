import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../service/auth_service.dart';
import '../login_screen.dart';
import 'admin_edit_profile_screen.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  // 1. สร้างตัวแปรเก็บข้อมูล admin ทั้งหมดไว้ที่นี่
  Map<String, dynamic>? adminData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAuthData();
  }

  Future<void> _loadAuthData() async {
    // 2. ดึงข้อมูลทั้งหมดมาเก็บในตัวแปรเดียว
    final name = await AuthService.getName();
    final role = await AuthService.getRole();
    final profile = await AuthService.getProfile();
    final uid = await AuthService.getUid();
    
    if (mounted) {
      setState(() {
        adminData = {
          "u_name": name ?? "ผู้ดูแลระบบ",
          "u_role": role ?? "admin",
          "u_profile": profile ?? "",
          "uid": uid ?? ""
        };
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("ออกจากระบบ", style: GoogleFonts.prompt()),
        content: Text("คุณต้องการออกจากระบบผู้ดูแลใช่หรือไม่?", style: GoogleFonts.prompt()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text("ยกเลิก")),
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
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
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
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF0D47A1), width: 3)),
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: adminData!['u_profile'],
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const Icon(Icons.admin_panel_settings, size: 60, color: Color(0xFF0D47A1)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(adminData!['u_name'], style: GoogleFonts.prompt(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF0D47A1))),
                    Text("สถานะ: ${adminData!['u_role'].toUpperCase()}", style: GoogleFonts.prompt(fontSize: 14, color: Colors.grey[600])),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)]),
                child: _buildAdminMenu(
                  icon: Icons.manage_accounts,
                  title: "แก้ไขข้อมูลส่วนตัว",
                  onTap: () async {
                    // รอให้กลับมาแล้วอัปเดตข้อมูลใหม่
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AdminEditProfileScreen(adminData: adminData!)),
                    );
                    _loadAuthData(); // โหลดข้อมูลใหม่หลังจากแก้ไขเสร็จ
                  },
                ),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity, height: 55,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFEBEE), foregroundColor: Colors.red[700], elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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

  Widget _buildAdminMenu({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: const Color(0xFF0D47A1))),
      title: Text(title, style: GoogleFonts.prompt(fontSize: 16, color: Colors.black87)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}