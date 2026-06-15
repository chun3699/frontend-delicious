import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

// Import ไฟล์ที่จำเป็นสำหรับการเชื่อมต่อ API (แก้ไข Path ให้ตรงกับโฟลเดอร์ของคุณ)
import '../../config/config.dart';
import '../../service/auth_service.dart';

import 'admin_add_user_screen.dart';
import 'admin_edit_user_screen.dart'; // อย่าลืมสร้างไฟล์นี้ตามโค้ดด้านล่าง

class AdminSearchUsersScreen extends StatefulWidget {
  const AdminSearchUsersScreen({super.key});
  @override
  State<AdminSearchUsersScreen> createState() => _AdminSearchUsersScreenState();
}

class _AdminSearchUsersScreenState extends State<AdminSearchUsersScreen> {
  String searchQuery = "";
  String selectedRole = "ทั้งหมด";
  bool isLoading = true; // เพิ่มตัวแปรสำหรับโหลด

  final TextEditingController _searchController = TextEditingController();
  final List<String> roles = ["ทั้งหมด", "user", "admin"];
  List<Map<String, dynamic>> allUsers = []; // เปลี่ยนเป็นข้อมูลว่างรอรับจาก API

  @override
  void initState() {
    super.initState();
    _fetchUsers(); // โหลดข้อมูลทันทีที่เปิดหน้านี้
  }

  // ==========================================
  // 1. API: ดึงข้อมูลผู้ใช้งานทั้งหมด
  // ==========================================
  Future<void> _fetchUsers() async {
    setState(() => isLoading = true);
    try {
      final config = await Configuration.getConfig();
      final apiEndpoint = config['apiEndpoint'];
      final String? token = await AuthService.getToken(); // ดึง Token

      final response = await http.get(
        Uri.parse("$apiEndpoint/users"),
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          allUsers = List<Map<String, dynamic>>.from(data);
          isLoading = false;
        });
      } else {
        _showSnackBar("ดึงข้อมูลล้มเหลว (Status: ${response.statusCode})", Colors.red);
        setState(() => isLoading = false);
      }
    } catch (e) {
      _showSnackBar("ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้", Colors.red);
      setState(() => isLoading = false);
    }
  }

  // ==========================================
  // 2. API: ลบผู้ใช้งาน
  // ==========================================
  Future<void> _deleteUserAPI(int uid) async {
    try {
      final config = await Configuration.getConfig();
      final apiEndpoint = config['apiEndpoint'];
      final String? token = await AuthService.getToken();

      final response = await http.delete(
        Uri.parse("$apiEndpoint/delete/$uid"), // ⚠️ แก้ไขเส้น API ให้ตรงกับ Backend
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        _showSnackBar("ลบบัญชีผู้ใช้งานสำเร็จ", Colors.green);
        _fetchUsers(); // รีเฟรชข้อมูลใหม่หลังจากลบ
      } else {
        _showSnackBar("ไม่สามารถลบผู้ใช้งานได้", Colors.red);
      }
    } catch (e) {
      _showSnackBar("ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้", Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: GoogleFonts.prompt()), backgroundColor: color),
    );
  }

  // ฟังก์ชันแสดงหน้าต่างยืนยันการลบผู้ใช้
  void _confirmDeleteUser(int index, Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text("ยืนยันการลบ?", style: GoogleFonts.prompt(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text(
          "คุณต้องการลบบัญชี '${user['u_name']}' ออกจากระบบใช่หรือไม่? ข้อมูลนี้ไม่สามารถกู้คืนได้",
          style: GoogleFonts.prompt(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // ปิดหน้าต่าง
            child: Text("ยกเลิก", style: GoogleFonts.prompt(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context); // ปิด Dialog ก่อน
              _deleteUserAPI(user['uid']); // เรียกฟังก์ชันลบผ่าน API
            },
            child: Text("ลบบัญชี", style: GoogleFonts.prompt(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // กรองข้อมูลตามการค้นหาและสิทธิ์
    List<Map<String, dynamic>> filteredUsers = allUsers.where((user) {
      bool matchesSearch = (user['u_name'] ?? '').toString().toLowerCase().contains(searchQuery.toLowerCase());
      bool matchesRole = selectedRole == "ทั้งหมด" || (user['u_role'] ?? 'user') == selectedRole;
      return matchesSearch && matchesRole;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF0D47A1)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("จัดการผู้ใช้งาน", style: GoogleFonts.prompt(color: const Color(0xFF0D47A1), fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1, color: Color(0xFF00ACC1), size: 28),
            onPressed: () async {
              // รอให้หน้าต่างเพิ่มผู้ใช้ปิดลง แล้วสั่งโหลดข้อมูลใหม่
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminAddUserScreen()),
              );
              _fetchUsers(); 
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator()) // แสดงวงกลมโหลดตอนดึง API
        : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "พบบัญชีทั้งหมด ${filteredUsers.length} รายการ",
              style: GoogleFonts.prompt(fontSize: 15, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 15),

          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: "ค้นหาด้วยชื่อผู้ใช้งาน...",
                hintStyle: GoogleFonts.prompt(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF1976D2)),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          const SizedBox(height: 15),

          // 2. แถบแยกประเภทสิทธิ์ (Role Filter)
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: roles.length,
              itemBuilder: (context, index) {
                String role = roles[index];
                bool isSelected = selectedRole == role;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    showCheckmark: false,
                    label: Text(
                      role.toUpperCase(),
                      style: GoogleFonts.prompt(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? const Color(0xFF0D47A1) : Colors.grey[700],
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF0D47A1).withOpacity(0.1),
                    backgroundColor: Colors.grey[100],
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onSelected: (selected) => setState(() => selectedRole = role),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 15),

          // 3. รายการผู้ใช้งาน (List View)
          Expanded(
            child: filteredUsers.isEmpty
                ? Center(child: Text("ไม่พบรายชื่อผู้ใช้งาน", style: GoogleFonts.prompt(color: Colors.grey, fontSize: 16)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 15.0),
                        child: Slidable(
                          key: ValueKey(user['uid']),
                          endActionPane: ActionPane(
                            motion: const ScrollMotion(),
                            children: [
                              SlidableAction(
                                onPressed: (context) => _confirmDeleteUser(index, user),
                                backgroundColor: const Color(0xFFFE4A49),
                                foregroundColor: Colors.white,
                                icon: Icons.delete,
                                label: 'ลบ',
                                borderRadius: const BorderRadius.only(topRight: Radius.circular(15), bottomRight: Radius.circular(15)),
                              ),
                            ],
                          ),
                          child: _buildUserCard(user),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Widget สร้างการ์ดผู้ใช้งาน
  Widget _buildUserCard(Map<String, dynamic> user) {
    bool isAdmin = user['u_role'] == 'admin';
    String profileUrl = (user['u_profile'] != null && user['u_profile'] != "-" && user['u_profile'].toString().isNotEmpty) 
        ? user['u_profile'] 
        : "https://cdn-icons-png.flaticon.com/512/3135/3135715.png";

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, spreadRadius: 1, offset: const Offset(0, 3))
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        onTap: () async {
          // กดเพื่อเปิดหน้าต่างแก้ไข และรอให้แก้ไขเสร็จเพื่อโหลดข้อมูลใหม่
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AdminEditUserScreen(userData: user)),
          );

          //เมื่อกลับมาหน้านี้ ให้ล้างคำค้นหาทิ้ง เพื่อให้โชว์รายชื่อทั้งหมด
          setState(() {
            _searchController.clear();
            searchQuery = ""; 
          });

          //สั่งให้ดึงข้อมูลจาก Database ใหม่อีกครั้งเพื่ออัปเดต UI
          _fetchUsers();
        },
        leading: Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: isAdmin ? const Color(0xFF1976D2) : Colors.grey[300]!, width: 2),
          ),
          child: ClipOval(
            child: CachedNetworkImage(
              imageUrl: profileUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 2),
              errorWidget: (context, url, error) => const Icon(Icons.person, color: Colors.grey),
            ),
          ),
        ),
        title: Text(
          user['u_name'] ?? 'ไม่ระบุชื่อ',
          style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0D47A1)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isAdmin ? const Color(0xFF1976D2).withOpacity(0.1) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  (user['u_role'] ?? 'user').toString().toUpperCase(),
                  style: GoogleFonts.prompt(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isAdmin ? const Color(0xFF1976D2) : Colors.grey[700],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text("ID: ${user['uid']}", style: GoogleFonts.prompt(fontSize: 12, color: Colors.grey[500])),
            ],
          ),
        ),
        trailing: const Icon(Icons.edit_note, color: Colors.grey),
      ),
    );
  }
}