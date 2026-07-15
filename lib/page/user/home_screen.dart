import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/page/detail/food_detail_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:http/http.dart' as http;
import '../../config/config.dart';
import '../../service/auth_service.dart';
import 'recommendation_screen.dart'; 
import '../search/food_search_screen.dart'; 
import '../search/ingredient_search_screen.dart';
import 'inventory_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> recommendFoods = [];
  List<Map<String, dynamic>> myIngredients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  // เพิ่มตัวแปรเหล่านี้ใน _HomeScreenState
String userName = "ผู้ใช้งาน";
String profileUrl = "";

// ปรับปรุง _loadAllData
Future<void> _loadAllData() async {
  setState(() => _isLoading = true);
  try {
    // 1. ดึงข้อมูลผู้ใช้จาก AuthService
    final name = await AuthService.getName();
    final profile = await AuthService.getProfile();
    
    // 2. ดึง Token และ Config
    final String? token = await AuthService.getToken();
    final String? uid = await AuthService.getUid();
    final config = await Configuration.getConfig();
    final api = config['apiEndpoint'];

    // 3. ดึงคลังวัตถุดิบ (คงเดิม)
    final invRes = await http.get(Uri.parse("$api/uability/inventory/$uid"), headers: {"Authorization": "Bearer $token"});
    List<int> invIds = [];
    if (invRes.statusCode == 200) {
      final invData = jsonDecode(invRes.body)['data'] as List;
      invIds = invData.map<int>((i) => i['ing_id'] as int).toList();
      setState(() => myIngredients = List<Map<String, dynamic>>.from(invData));
    }

    // 4. ดึงรายการแนะนำ (คงเดิม)
    final recRes = await http.post(
      Uri.parse("$api/food/recommend"),
      headers: {"Authorization": "Bearer $token", "Content-Type": "application/json"},
      body: jsonEncode({"userInventoryIds": invIds}),
    );

    if (recRes.statusCode == 200) {
      setState(() => recommendFoods = List<Map<String, dynamic>>.from(jsonDecode(recRes.body)['data']));
    }

    // อัปเดต State ข้อมูลผู้ใช้
    setState(() {
      userName = name ?? "ผู้ใช้งาน";
      profileUrl = profile ?? "";
    });
  } catch (e) {
    debugPrint("Error loading home data: $e");
  } finally {
    setState(() => _isLoading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  Text("ค้นหาด่วน", style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildQuickSearchButton(context, "ค้นหาอาหาร", Icons.restaurant_menu, const Color(0xFF1976D2), const FoodSearchScreen()),
                      const SizedBox(width: 15),
                      _buildQuickSearchButton(context, "ค้นหาวัตถุดิบ", Icons.shopping_basket, const Color(0xFF00ACC1), IngredientSearchScreen()),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("เมนูแนะนำสำหรับคุณ", style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.bold)),
                      if (recommendFoods.isNotEmpty)
                        TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RecommendationScreen())),
                          child: Text("ดูทั้งหมด", style: GoogleFonts.prompt(color: const Color(0xFF00ACC1))),
                        ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  recommendFoods.isEmpty 
                      ? _buildEmptyRecommendCard(context) 
                      : _buildCarouselSlider(),
                  const SizedBox(height: 30),
                  _buildHorizontalIngredients(context),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildHeader() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Expanded(
        child: Text(
          "สวัสดี, $userName 👋", 
          style: GoogleFonts.prompt(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF0D47A1)),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      const SizedBox(width: 10),
      CircleAvatar(
        radius: 22,
        backgroundColor: Colors.grey[200],
        backgroundImage: profileUrl.isNotEmpty 
            ? CachedNetworkImageProvider(profileUrl) 
            : null,
        child: profileUrl.isEmpty ? const Icon(Icons.person, color: Colors.grey) : null,
      ),
    ],
  );
}

  Widget _buildQuickSearchButton(BuildContext context, String label, IconData icon, Color color, Widget destination) {
    return Expanded(
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => destination)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(0.3))),
          child: Column(children: [Icon(icon, color: color, size: 30), const SizedBox(height: 8), Text(label, style: GoogleFonts.prompt(color: color, fontWeight: FontWeight.w600, fontSize: 14))]),
        ),
      ),
    );
  }

  Widget _buildEmptyRecommendCard(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey[300]!)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.no_food_outlined, size: 50, color: Colors.grey[400]),
          const SizedBox(height: 10),
          Text("ยังไม่มีวัตถุดิบพอที่จะแนะนำเมนู", style: GoogleFonts.prompt(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00ACC1)),
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text("ไปเพิ่มวัตถุดิบเลย", style: GoogleFonts.prompt(color: Colors.white)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => IngredientSearchScreen())),
          )
        ],
      ),
    );
  }

  Widget _buildCarouselSlider() {
    return CarouselSlider(
      options: CarouselOptions(
        height: 180.0, 
        enlargeCenterPage: true, 
        autoPlay: true
      ),
      items: recommendFoods.map((food) {
        return GestureDetector(
          onTap: () async {
            // ดึงข้อมูลรายละเอียดเมนูเพื่อส่งไปหน้า Detail
            final config = await Configuration.getConfig();
            final token = await AuthService.getToken();
            final api = config['apiEndpoint'];
            
            final res = await http.get(
              Uri.parse("$api/food/${food['recipeId']}"), // ใช้ recipeId จาก API แนะนำ
              headers: {"Authorization": "Bearer $token"}
            );
            
            if (res.statusCode == 200) {
              Navigator.push(context, MaterialPageRoute(builder: (context) => 
                FoodDetailScreen(
                  foodData: jsonDecode(res.body), 
                  myInventory: myIngredients // ส่งคลังไปด้วยเพื่อให้เช็ควัตถุดิบได้
                )
              ));
            }
          },
          child: Stack(
            children: [
              // รูปภาพเมนูอาหาร
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: CachedNetworkImage(
                  imageUrl: food['food_image'] ?? "", 
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 180,
                  errorWidget: (context, url, error) => Container(color: Colors.grey[300], child: const Icon(Icons.restaurant)),
                ),
              ),
              // เงาดำให้ข้อความอ่านง่าย
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter
                  )
                ),
              ),
              // ชื่อเมนู
              Positioned(
                bottom: 15,
                left: 15,
                right: 15,
                child: Text(
                  food['recipeName'], 
                  style: GoogleFonts.prompt(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHorizontalIngredients(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("วัตถุดิบในคลังของคุณ", style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.bold)),
            if (myIngredients.isNotEmpty)
              TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InventoryScreen())), child: Text("ดูทั้งหมด", style: GoogleFonts.prompt(color: const Color(0xFF00ACC1)))),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: myIngredients.isEmpty
              ? _buildEmptyIngredientAction(context)
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: myIngredients.length,
                  itemBuilder: (context, index) => _buildIngredientItemCard(myIngredients[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyIngredientAction(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => IngredientSearchScreen())),
      child: Container(
        width: 150,
        decoration: BoxDecoration(color: const Color(0xFFE0F7FA).withOpacity(0.5), borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFF00ACC1).withOpacity(0.5))),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.add_circle_outline, color: Color(0xFF00ACC1), size: 35), const SizedBox(height: 8), Text("เพิ่มวัตถุดิบเลย", style: GoogleFonts.prompt(color: const Color(0xFF0D47A1), fontWeight: FontWeight.bold))]),
      ),
    );
  }

  Widget _buildIngredientItemCard(Map<String, dynamic> item) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 15),
      child: Column(
        children: [
          // ⭐️ ปรับจาก CircleAvatar ที่มีไอคอน เป็นการใช้ ClipRRect แสดงรูปภาพ
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              imageUrl: item['ing_image'] ?? '',
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Container(
                width: 50,
                height: 50,
                color: Colors.grey[200],
                child: const Icon(Icons.fastfood, color: Colors.orange, size: 25),
              ),
            ),
          ),
          const SizedBox(height: 5),
          // ชื่อวัตถุดิบ
          Text(
            item['ing_name'] ?? "",
            style: GoogleFonts.prompt(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}