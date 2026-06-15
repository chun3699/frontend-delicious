import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

import '../page/admin/admin_home_screen.dart';
import '../page/admin/admin_profile_screen.dart';

class AdminMainNavigation extends StatefulWidget {
  const AdminMainNavigation({super.key});

  @override
  State<AdminMainNavigation> createState() => _AdminMainNavigationState();
}

class _AdminMainNavigationState extends State<AdminMainNavigation> {
  int _currentIndex = 0;

  // รายการหน้าจอหลักของแอดมิน 2 หน้า
  final List<Widget> _screens = [
    AdminHomeScreen(),
    AdminProfileScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)
          ]
        ),
        child: SalomonBottomBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: [
            SalomonBottomBarItem(
              icon: const Icon(Icons.dashboard_rounded),
              title: const Text("หน้าหลัก"),
              selectedColor: const Color(0xFF0D47A1), // Navy Blue
            ),
            SalomonBottomBarItem(
              icon: const Icon(Icons.admin_panel_settings_rounded),
              title: const Text("โปรไฟล์"),
              selectedColor: const Color(0xFF00ACC1), // Cyan
            ),
          ],
        ),
      ),
    );
  }
}