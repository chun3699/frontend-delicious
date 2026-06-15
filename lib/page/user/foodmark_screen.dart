import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import '../../config/config.dart';
import '../../service/auth_service.dart';
import '../detail/food_detail_screen.dart';
import '../search/food_search_screen.dart';

class FoodmarkScreen extends StatefulWidget {
  const FoodmarkScreen({super.key});

  @override
  State<FoodmarkScreen> createState() => _FoodmarkScreenState();
}

class _FoodmarkScreenState extends State<FoodmarkScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> favoriteFoods = [];
  List<Map<String, dynamic>> myIngredients = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final String? uid = await AuthService.getUid();
      final String? token = await AuthService.getToken();
      final config = await Configuration.getConfig();
      final apiEndpoint = config['apiEndpoint'];

      if (uid == null || token == null) return;

      // 1. ดึงรายการโปรด
      final favRes = await http.get(
        Uri.parse("$apiEndpoint/foodmark/my-favorite/$uid"),
        headers: {"Authorization": "Bearer $token"},
      );

      // 2. ดึงคลังวัตถุดิบ (เพื่อใช้เช็คในหน้า Detail)
      final invRes = await http.get(
        Uri.parse("$apiEndpoint/uability/inventory/$uid"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (favRes.statusCode == 200 && invRes.statusCode == 200) {
        setState(() {
          favoriteFoods = List<Map<String, dynamic>>.from(jsonDecode(favRes.body));
          myIngredients = List<Map<String, dynamic>>.from(jsonDecode(invRes.body)['data'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("รายการอาหารโปรด", 
                    style: GoogleFonts.prompt(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF0D47A1))),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Color(0xFF00ACC1), size: 32),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FoodSearchScreen())).then((_) => _loadData()),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : favoriteFoods.isEmpty
                        ? Center(child: Text("ยังไม่มีเมนูโปรด", style: GoogleFonts.prompt(color: Colors.grey)))
                        : GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.8,
                            ),
                            itemCount: favoriteFoods.length,
                            itemBuilder: (context, index) => _buildFoodCard(favoriteFoods[index]),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoodCard(Map<String, dynamic> food) {
    return GestureDetector(
      onTap: () async {
        final config = await Configuration.getConfig();
        final String? token = await AuthService.getToken();
        final res = await http.get(
          Uri.parse("${config['apiEndpoint']}/food/${food['food_id']}"),
          headers: {"Authorization": "Bearer $token"},
        );
        
        if (res.statusCode == 200) {
          // ✅ หัวใจสำคัญ: ใช้ .then() เพื่อสั่งรีเฟรชข้อมูลเมื่อกลับมาหน้านี้
          Navigator.push(context, MaterialPageRoute(builder: (_) => FoodDetailScreen(
            foodData: jsonDecode(res.body),
            myInventory: myIngredients,
          ))).then((_) => _loadData()); 
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.circular(15), 
          boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.1), blurRadius: 10)]
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)), 
                child: CachedNetworkImage(
                  imageUrl: food['food_image'] ?? "", 
                  fit: BoxFit.cover, 
                  width: double.infinity,
                  errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                )
              )
            ),
            Padding(
              padding: const EdgeInsets.all(10), 
              child: Text(food['food_name'] ?? "", 
                style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            ),
          ],
        ),
      ),
    );
  }
}