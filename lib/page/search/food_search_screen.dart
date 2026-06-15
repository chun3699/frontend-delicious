import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import '../../config/config.dart';
import '../../service/auth_service.dart'; // 🔑 อย่าลืม Import Service นี้
import '../detail/food_detail_screen.dart';

class FoodSearchScreen extends StatefulWidget {
  const FoodSearchScreen({super.key});
  @override
  _FoodSearchScreenState createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  String searchQuery = "";
  String selectedCategory = "ทั้งหมด";
  bool _isLoading = true;
  List<Map<String, dynamic>> allFoods = [];
  List<Map<String, dynamic>> myIngredients = [];
  List<String> categories = ["ทั้งหมด"];

  @override
  void initState() {
    super.initState();
    _fetchFoods();
    _fetchInventory(); // 👈 ต้องเพิ่มบรรทัดนี้ เพื่อไปดึงข้อมูลคลังมาเก็บไว้ใน myIngredients
  }

  // เพิ่มฟังก์ชันนี้ลงในคลาส _FoodSearchScreenState
  Future<void> _fetchInventory() async {
    try {
      final String? uidStr = await AuthService.getUid();
      final String? token = await AuthService.getToken();
      final config = await Configuration.getConfig();
      final apiEndpoint = config['apiEndpoint'];

      final response = await http.get(
        Uri.parse("$apiEndpoint/uability/inventory/$uidStr"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          // ตรวจสอบโครงสร้าง JSON จาก API ของคุณอีกครั้ง 
          // ถ้า API ส่งกลับมาเป็น List เลยให้ใช้ jsonDecode(response.body) 
          // ถ้าส่งมาเป็น { "data": [...] } ให้ใช้ result['data']
          myIngredients = List<Map<String, dynamic>>.from(result['data'] ?? []);
        });
      }
    } catch (e) {
      debugPrint("Error fetching inventory: $e");
    }
  }

  Future<void> _fetchFoods() async {
    try {
      final String? token = await AuthService.getToken();
      final config = await Configuration.getConfig();
      final apiEndpoint = config['apiEndpoint'];

      final response = await http.get(
        Uri.parse("$apiEndpoint/food"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          allFoods = List<Map<String, dynamic>>.from(data);
          final uniqueCats = allFoods
              .map((f) => f['food_type_name']?.toString() ?? "อื่นๆ")
              .toSet();
          categories.addAll(uniqueCats);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredList = allFoods.where((item) {
      final name = item['food_name']?.toString().toLowerCase() ?? "";
      final category = item['food_type_name']?.toString() ?? "อื่นๆ";
      bool matchesSearch = name.contains(searchQuery.toLowerCase());
      bool matchesCategory =
          selectedCategory == "ทั้งหมด" || category == selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "ค้นหาเมนูอาหาร",
          style: GoogleFonts.prompt(
            color: const Color(0xFF0D47A1),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF0D47A1)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: TextField(
                    onChanged: (value) => setState(() => searchQuery = value),
                    decoration: InputDecoration(
                      hintText: "ค้นหาเมนูที่อยากทาน...",
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF1976D2),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    itemCount: categories.length,
                    itemBuilder: (ctx, i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: ChoiceChip(
                        label: Text(
                          categories[i],
                          style: GoogleFonts.prompt(
                            color: selectedCategory == categories[i]
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                        selected: selectedCategory == categories[i],
                        selectedColor: const Color(0xFF0D47A1),
                        onSelected: (_) =>
                            setState(() => selectedCategory = categories[i]),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: filteredList.length,
                    itemBuilder: (ctx, i) {
                      final item = filteredList[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 15),
                        child: ListTile(
                          leading: CachedNetworkImage(
                            imageUrl: item['food_image'] ?? '',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                          title: Text(
                            item['food_name'],
                            style: GoogleFonts.prompt(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            "หมวดหมู่: ${item['food_type_name'] ?? 'อื่นๆ'}",
                            style: GoogleFonts.prompt(fontSize: 12),
                          ),
                          onTap: () async {
                            final String? token = await AuthService.getToken();
                            final config = await Configuration.getConfig();
                            final res = await http.get(
                              Uri.parse(
                                "${config['apiEndpoint']}/food/${item['food_id']}",
                              ),
                              headers: {"Authorization": "Bearer $token"},
                            );
                            if (res.statusCode == 200) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FoodDetailScreen(
                                    foodData: jsonDecode(res.body),
                                    myInventory:
                                        myIngredients, // ⬅️ ส่งค่าคลังวัตถุดิบไปที่นี่
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
