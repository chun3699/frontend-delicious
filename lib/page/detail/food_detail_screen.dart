import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import '../../config/config.dart';
import '../../service/auth_service.dart';

class FoodDetailScreen extends StatefulWidget {
  final Map<String, dynamic> foodData;
  final List<Map<String, dynamic>> myInventory;

  const FoodDetailScreen({
    super.key,
    required this.foodData,
    required this.myInventory,
  });

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {
  bool isFavorite = false;
  bool isFavLoading = true;

  @override
  void initState() {
    super.initState();
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    final String? uid = await AuthService.getUid();
    final String? token = await AuthService.getToken();
    final config = await Configuration.getConfig();

    if (uid == null || token == null) return;

    try {
      final response = await http.get(
        Uri.parse(
          "${config['apiEndpoint']}/foodmark/check/$uid/${widget.foodData['food_id']}",
        ),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          isFavorite = jsonDecode(response.body)['isFavorite'] ?? false;
          isFavLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error checking favorite: $e");
    }
  }

  Future<void> _toggleFavorite() async {
    final String? uid = await AuthService.getUid();
    final String? token = await AuthService.getToken();
    final config = await Configuration.getConfig();

    setState(() => isFavorite = !isFavorite);

    try {
      final url =
          "${config['apiEndpoint']}/foodmark/${isFavorite ? 'add' : 'remove'}";
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"uid": uid, "food_id": widget.foodData['food_id']}),
      );

      if (response.statusCode != 200) {
        setState(() => isFavorite = !isFavorite);
      }
    } catch (e) {
      setState(() => isFavorite = !isFavorite);
      debugPrint("Error toggling favorite: $e");
    }
  }

  Future<void> _cookFood(BuildContext context) async {
    final String? token = await AuthService.getToken();
    final String? uid = await AuthService.getUid();
    final config = await Configuration.getConfig();

    try {
      final response = await http.post(
        Uri.parse("${config['apiEndpoint']}/food/cook"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"uid": uid, "food_id": widget.foodData['food_id']}),
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("ปรุงอาหารสำเร็จ!")));
        Navigator.pop(context);
      } else {
        final error = jsonDecode(response.body)['error'];
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error ?? "วัตถุดิบไม่เพียงพอ")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("เกิดข้อผิดพลาดในการเชื่อมต่อ")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List ingredients = widget.foodData['ingredients'] as List? ?? [];
    bool canCook = true;

    for (var ing in ingredients) {
      // ค้นหาว่ามีวัตถุดิบนี้ในคลังหรือไม่ (เช็คแค่ว่ามีหรือไม่มี)
      final invItem = widget.myInventory.firstWhere(
        (i) => i['ing_id'] == ing['ing_id'],
        orElse: () => {'amount': 0},
      );

      // ปรับเงื่อนไข: ถ้า amount ในคลังเป็น 0 หรือไม่มีในคลัง คือปรุงไม่ได้
      if ((invItem['amount'] ?? 0) <= 0) {
        canCook = false;
        break;
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            pinned: true,
            actions: [
              isFavLoading
                  ? const Padding(
                      padding: EdgeInsets.all(15),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.pink : Colors.white,
                        size: 30,
                      ),
                      onPressed: _toggleFavorite,
                    ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: CachedNetworkImage(
                imageUrl: widget.foodData['food_image'] ?? "",
                fit: BoxFit.cover,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.foodData['food_name'] ?? "",
                    style: GoogleFonts.prompt(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0D47A1),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "วัตถุดิบที่ต้องใช้:",
                    style: GoogleFonts.prompt(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F7FA),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: ingredients.map((ing) {
                        final invItem = widget.myInventory.firstWhere(
                          (i) => i['ing_id'] == ing['ing_id'],
                          orElse: () => {'amount': 0},
                        );
                        int has = invItem['amount'] ?? 0;
                        int needed =
                            int.tryParse(ing['amount'].toString()) ?? 0;
                        bool isEnough = has >= needed;
                        // และในส่วนการแสดงผลรายการวัตถุดิบ:
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                ing['ing_name'] ?? "",
                                style: GoogleFonts.prompt(
                                  color: (invItem['amount'] ?? 0) > 0
                                      ? Colors.black87
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                (invItem['amount'] ?? 0) > 0
                                    ? "มีวัตถุดิบ"
                                    : "ไม่มีวัตถุดิบ",
                                style: GoogleFonts.prompt(
                                  color: (invItem['amount'] ?? 0) > 0
                                      ? Colors.blue
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "วิธีทำ:",
                    style: GoogleFonts.prompt(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.foodData['food_description'] ?? "ไม่มีข้อมูล",
                    style: GoogleFonts.prompt(fontSize: 15, height: 1.5),
                  ),
                  const SizedBox(height: 40),
                  
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
