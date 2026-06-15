import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import '../page/user/home_screen.dart';
import '../page/user/inventory_screen.dart';
import '../page/user/profile_screen.dart';
import '../page/user/foodmark_screen.dart';
import '../page/user/scanner_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // รายการหน้าจอที่จะเปลี่ยนไปมา
  final List<Widget> _screens = [
    HomeScreen(),
    InventoryScreen(),
    ScannerScreen(),
    FoodmarkScreen(),
    ProfileScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: SalomonBottomBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: [
          SalomonBottomBarItem(
            icon: const Icon(Icons.home),
            title: const Text("หน้าแรก"),
            selectedColor: const Color(0xFF0D47A1), // Navy Blue
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.kitchen),
            title: const Text("วัตถุดิบ"),
            selectedColor: const Color(0xFF00ACC1), // Cyan
          ),
          // --- 2. เพิ่มปุ่มสแกนกล้อง ไว้ตรงกลาง ---
          SalomonBottomBarItem(
            icon: const Icon(Icons.camera_alt),
            title: const Text("สแกน"),
            selectedColor: const Color(0xFF0D47A1), // ใช้สีน้ำเงินเข้มให้ดูโดดเด่นเหมือนเดิม
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.favorite),
            title: const Text("รายการโปรด"),
            selectedColor: Colors.pink,
          ),
          SalomonBottomBarItem(
            icon: const Icon(Icons.person),
            title: const Text("โปรไฟล์"),
            selectedColor: const Color(0xFF1976D2), // Blue
          ),
        ],
      ),
      
    );
  }
}