import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _tokenKey = 'jwt_token';
  static const String _roleKey = 'user_role';
  static const String _uidKey = 'uid';
  static const String _nameKey = 'user_name';
  static const String _profileKey = 'user_profile'; // 1. เพิ่ม Key สำหรับรูปโปรไฟล์

  // 2. ปรับฟังก์ชันรับค่าเพิ่ม 'profile'
  static Future<void> saveLoginData(String token, String role, String uid, String name, String profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_roleKey, role);
    await prefs.setString(_uidKey, uid);
    await prefs.setString(_nameKey, name);
    await prefs.setString(_profileKey, profile); // บันทึกรูปโปรไฟล์
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }

  // 3. เพิ่มฟังก์ชันดึงรูปโปรไฟล์
  static Future<String?> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_profileKey);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<String?> getUid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_uidKey);
  }

}