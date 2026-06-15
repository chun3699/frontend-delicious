import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../admin/admin_add_food_screen.dart';
import 'admin_search_users_screen.dart';
import 'admin_search_food_screen.dart';
import 'admin_search_ingredients_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header ส่วนหัว
              Text(
                "ระบบจัดการผู้ดูแลระบบ",
                style: GoogleFonts.prompt(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0D47A1),
                ),
              ),
              Text(
                "เลือกฟังก์ชันที่ต้องการควบคุมและตรวจสอบ",
                style: GoogleFonts.prompt(fontSize: 15, color: Colors.grey[600]),
              ),
              const SizedBox(height: 35),

              // ส่วนปุ่มเมนูหลักแบบ Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                  childAspectRatio: 0.95,
                  children: [
                    _buildMenuCard(
                      context,
                      title: "เพิ่มเมนูอาหาร",
                      subtitle: "จัดการสูตรอาหารใหม่",
                      icon: Icons.add_photo_alternate_rounded,
                      color: const Color(0xFF1976D2), // Blue
                      destination: AdminAddFoodScreen(),
                    ),
                    _buildMenuCard(
                      context,
                      title: "ค้นหาผู้ใช้",
                      subtitle: "ตรวจสอบและจัดการสมาชิก",
                      icon: Icons.supervised_user_circle_rounded,
                      color: const Color(0xFF00ACC1), // Cyan
                      destination: AdminSearchUsersScreen(),
                    ),
                    _buildMenuCard(
                      context,
                      title: "ค้นหาเมนูอาหาร",
                      subtitle: "ดูและแก้ไขรายการอาหาร",
                      icon: Icons.restaurant_menu_rounded,
                      color: const Color(0xFF0288D1), // Light Blue
                      destination: AdminSearchFoodScreen(),
                    ),
                    _buildMenuCard(
                      context,
                      title: "ค้นหาวัตถุดิบ",
                      subtitle: "ตรวจสอบคลังวัตถุดิบกลาง",
                      icon: Icons.breakfast_dining_rounded,
                      color: const Color(0xFF0097A7), // Dark Cyan
                      destination: AdminSearchIngredientsScreen(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget ตัวช่วยสร้างปุ่มการ์ดเมนู
  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget destination,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => destination));
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0D47A1)),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.prompt(fontSize: 12, color: Colors.grey[500]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}