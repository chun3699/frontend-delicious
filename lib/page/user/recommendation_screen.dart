import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import '../../config/config.dart';
import '../../service/auth_service.dart';
import '../detail/food_detail_screen.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  List<Map<String, dynamic>> recommendedList = [];
  List<Map<String, dynamic>> myInventory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRecommendations();
  }

  Future<void> _fetchRecommendations() async {
    setState(() => _isLoading = true);
    try {
      final String? token = await AuthService.getToken();
      final String? uid = await AuthService.getUid();
      final config = await Configuration.getConfig();
      final apiEndpoint = config['apiEndpoint'];

      // 1. ดึงคลังวัตถุดิบก่อนเพื่อส่ง ID ไปให้ API แนะนำอาหาร
      final invRes = await http.get(
        Uri.parse("$apiEndpoint/uability/inventory/$uid"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (invRes.statusCode == 200) {
        final List inventoryData = jsonDecode(invRes.body)['data'];

        setState(
          () => myInventory = List<Map<String, dynamic>>.from(inventoryData),
        );

        // ⭐️ กรองเอาเฉพาะวัตถุดิบที่ amount == 1 (สถานะ "มี") เท่านั้น ถึงจะเอา ID ไปคำนวณเมนูแนะนำ
        List<int> invIds = inventoryData
            .where((i) => i['amount'] == 1) // 👈 กรองตัวที่หมด (0) ออกไปทันที
            .map<int>((i) => i['ing_id'] as int)
            .toList();

        // จากนั้นค่อยส่ง invIds นี้ไปที่ API /recommend ต่อไป...
        final recRes = await http.post(
          Uri.parse("$apiEndpoint/food/recommend"),
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          body: jsonEncode({"userInventoryIds": invIds}),
        );

        if (recRes.statusCode == 200) {
          final List recData = jsonDecode(recRes.body)['data'];
          setState(() {
            recommendedList = List<Map<String, dynamic>>.from(recData);
          });
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF0D47A1)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "เมนูที่ทำได้จากวัตถุดิบของคุณ",
          style: GoogleFonts.prompt(
            color: const Color(0xFF0D47A1),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : recommendedList.isEmpty
          ? Center(
              child: Text(
                "ยังไม่มีเมนูที่ทำได้ตอนนี้",
                style: GoogleFonts.prompt(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: recommendedList.length,
              itemBuilder: (context, index) {
                final food = recommendedList[index];
                return GestureDetector(
                  onTap: () async {
                    // ดึงข้อมูลรายละเอียดเมนูเพื่อส่งไปหน้า Detail
                    final config = await Configuration.getConfig();
                    final token = await AuthService.getToken();
                    final res = await http.get(
                      Uri.parse(
                        "${config['apiEndpoint']}/food/${food['recipeId']}",
                      ),
                      headers: {"Authorization": "Bearer $token"},
                    );

                    if (res.statusCode == 200) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FoodDetailScreen(
                            foodData: jsonDecode(res.body),
                            myInventory: myInventory,
                          ),
                        ),
                      );
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(15),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: food['food_image'] ?? "",
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                food['recipeName'],
                                style: GoogleFonts.prompt(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "ความพร้อม: ${food['matchPercentage']}%",
                                style: GoogleFonts.prompt(
                                  color: food['canCookNow']
                                      ? Colors.green
                                      : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
