import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/config.dart';
import '../model/request/user_login_post_req.dart';
import '../nav/main_navigation.dart';
import '../nav/admin_main_navigation.dart';
import '../page/register_screen.dart';
import '../service/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool isPasswordHidden = true;
  bool isLoading = false;
  bool isGoogleLoading = false; // ✅ loading แยกสำหรับ Google

  // ✅ สร้าง GoogleSignIn instance
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId:
        "221645289676-63qduao82d6u8j2e9e8622lrm653oiva.apps.googleusercontent.com",
    scopes: ['email', 'profile'],
  );

  // ==========================================
  // ฟังก์ชัน Login ปกติ (โค้ดเดิม)
  // ==========================================
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);
      try {
        final config = await Configuration.getConfig();
        final apiEndpoint = config['apiEndpoint'];

        UserLoginPostReq reqData = UserLoginPostReq(
          username: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final response = await http.post(
          Uri.parse("$apiEndpoint/login"),
          headers: {"Content-Type": "application/json"},
          body: userLoginPostReqToJson(reqData),
        );

        final result = jsonDecode(response.body);
        if (response.statusCode == 200) {
          final String token = result['token'];
          final String role = result['user']?['u_role'] ?? 'user';
          final String uid =
              result['user']?['uid']?.toString() ??
              result['user']?['u_id']?.toString() ??
              '';

          await AuthService.saveLoginData(
            token,
            role,
            uid,
            result['user']['u_name'], // ชื่อ
            result['user']['u_profile'],
          );

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("เข้าสู่ระบบสำเร็จ", style: GoogleFonts.prompt()),
              backgroundColor: Colors.green,
            ),
          );

          _navigateByRole(role);
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['error'] ?? "อีเมลหรือรหัสผ่านไม่ถูกต้อง",
                style: GoogleFonts.prompt(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้: $error",
              style: GoogleFonts.prompt(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  // ==========================================
  // ✅ ฟังก์ชัน Google Login
  // ==========================================
  Future<void> _loginWithGoogle() async {
    setState(() => isGoogleLoading = true);
    try {
      // 1. เปิดหน้าต่าง Google Sign-In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // ผู้ใช้กด cancel
        setState(() => isGoogleLoading = false);
        return;
      }

      // 2. ดึง Authentication Token จาก Google
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        _showSnackBar("ไม่สามารถดึง Token จาก Google ได้", Colors.red);
        setState(() => isGoogleLoading = false);
        return;
      }

      // 3. ส่ง idToken ไปให้ Node.js ตรวจสอบ
      final config = await Configuration.getConfig();
      final apiEndpoint = config['apiEndpoint'];

      final response = await http.post(
        Uri.parse("$apiEndpoint/google-login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"idToken": idToken}),
      );

      final result = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final String token = result['token'];
        final String role = result['user']?['u_role'] ?? 'user';
        final String uid =
            result['user']?['uid']?.toString() ??
            result['user']?['u_id']?.toString() ??
            '';

        // 4. บันทึก token และ role ลงเครื่อง
        await AuthService.saveLoginData(
          token,
          role,
          uid,
          result['user']['u_name'], // ชื่อ
          result['user']['u_profile'],
        );

        if (!mounted) return;
        _showSnackBar("เข้าสู่ระบบด้วย Google สำเร็จ", Colors.green);
        _navigateByRole(role);
      } else {
        if (!mounted) return;
        _showSnackBar(result['error'] ?? "Google Login ล้มเหลว", Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar("เกิดข้อผิดพลาด: $e", Colors.red);
    } finally {
      if (mounted) setState(() => isGoogleLoading = false);
    }
  }

  // ==========================================
  // Helper functions
  // ==========================================
  void _navigateByRole(String role) {
    if (role == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AdminMainNavigation()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigation()),
      );
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.prompt()),
        backgroundColor: color,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ยินดีต้อนรับกลับมา!",
                  style: GoogleFonts.prompt(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0D47A1),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "เข้าสู่ระบบเพื่อค้นหาเมนูอร่อยจากวัตถุดิบของคุณ",
                  style: GoogleFonts.prompt(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 40),

                // ช่องกรอก Username
                _buildTextField(
                  "อีเมล",
                  Icons.email,
                  controller: _emailController,
                  validator: (value) =>
                      value!.isEmpty ? 'กรุณากรอกอีเมล' : null,
                ),
                const SizedBox(height: 20),

                // ช่องกรอก Password
                _buildTextField(
                  "รหัสผ่าน",
                  Icons.lock,
                  isPassword: true,
                  controller: _passwordController,
                  validator: (value) =>
                      value!.isEmpty ? 'กรุณากรอกรหัสผ่าน' : null,
                ),
                const SizedBox(height: 30),

                // ปุ่ม Login ปกติ
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isLoading ? null : _login,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            "เข้าสู่ระบบ",
                            style: GoogleFonts.prompt(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // ✅ Divider "หรือ"
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[300])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        "หรือ",
                        style: GoogleFonts.prompt(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[300])),
                  ],
                ),
                const SizedBox(height: 16),

                // ✅ ปุ่ม Google Login
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isGoogleLoading ? null : _loginWithGoogle,
                    child: isGoogleLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF1976D2),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Google logo (ใช้ icon แทนรูป)
                              Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.g_mobiledata,
                                  color: Color(0xFFEA4335),
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "เข้าสู่ระบบด้วย Google",
                                style: GoogleFonts.prompt(
                                  fontSize: 16,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // ลิงก์สมัครสมาชิก
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "ยังไม่มีบัญชีใช่ไหม? ",
                      style: GoogleFonts.prompt(
                        color: Colors.grey[600],
                        fontSize: 15,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "สมัครสมาชิก",
                        style: GoogleFonts.prompt(
                          color: const Color(0xFF00ACC1),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String hint,
    IconData icon, {
    bool isPassword = false,
    required TextEditingController controller,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && isPasswordHidden,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.prompt(color: Colors.grey[400]),
        prefixIcon: Icon(icon, color: const Color(0xFF1976D2)),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isPasswordHidden ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () =>
                    setState(() => isPasswordHidden = !isPasswordHidden),
              )
            : null,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
