import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;

import '../../config/config.dart';
import '../../service/auth_service.dart';

class IngredientSearchScreen extends StatefulWidget {
  const IngredientSearchScreen({super.key});

  @override
  _IngredientSearchScreenState createState() => _IngredientSearchScreenState();
}

class _IngredientSearchScreenState extends State<IngredientSearchScreen> {
  String searchQuery = "";
  int selectedCategoryId = 0;
  bool _isLoading = true;
  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> allIngredients = [];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    await Future.wait([_fetchCategories(), _fetchIngredients()]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchCategories() async {
    try {
      final config = await Configuration.getConfig();
      final apiEndpoint = config['apiEndpoint'];
      final String? token = await AuthService.getToken();

      final response = await http.get(
        Uri.parse("$apiEndpoint/ingredient/types/all"),
        headers: {"Content-Type": "application/json", if (token != null) "Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          categories = [{"ing_type_id": 0, "ing_type_name": "ทั้งหมด"}];
          categories.addAll(List<Map<String, dynamic>>.from(data));
        });
      }
    } catch (e) {
      debugPrint("Error fetching categories: $e");
    }
  }

  Future<void> _fetchIngredients() async {
    try {
      final config = await Configuration.getConfig();
      final apiEndpoint = config['apiEndpoint'];
      final String? token = await AuthService.getToken();

      final response = await http.get(
        Uri.parse("$apiEndpoint/ingredient"),
        headers: {"Content-Type": "application/json", if (token != null) "Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() => allIngredients = List<Map<String, dynamic>>.from(data));
      }
    } catch (e) {
      _showSnackBar("เชื่อมต่อเซิร์ฟเวอร์ไม่ได้");
    }
  }

  // ปรับปรุงใหม่: ไม่ต้องรับค่า amount แล้ว
  Future<void> _addToInventory(int ingId, String ingName) async {
    try {
      final String? uidStr = await AuthService.getUid();
      final String? token = await AuthService.getToken();
      final config = await Configuration.getConfig();
      final apiEndpoint = config['apiEndpoint'];

      final response = await http.post(
        Uri.parse("$apiEndpoint/uability/add-inventory"),
        headers: {"Content-Type": "application/json", "Authorization": "Bearer $token"},
        body: jsonEncode({"uid": int.parse(uidStr!), "ing_id": ingId}), // ไม่ส่ง amount แล้ว
      );

      if (response.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เพิ่ม $ingName ลงในคลังแล้ว!', style: GoogleFonts.prompt()), backgroundColor: Colors.green),
        );
      } else {
        final result = jsonDecode(response.body);
        _showSnackBar(result['message'] ?? 'มีวัตถุดิบนี้ในคลังแล้ว');
      }
    } catch (e) {
      _showSnackBar("เกิดข้อผิดพลาดในการเชื่อมต่อ");
    }
  }

  String _getCategoryName(int typeId) {
    final cat = categories.firstWhere((e) => e['ing_type_id'] == typeId, orElse: () => {"ing_type_name": "ไม่ระบุ"});
    return cat['ing_type_name'];
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message, style: GoogleFonts.prompt()), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredList = allIngredients.where((item) {
      bool matchesSearch = (item['ing_name'] ?? '').toString().toLowerCase().contains(searchQuery.toLowerCase());
      bool matchesCategory = selectedCategoryId == 0 || item['ing_type_id'] == selectedCategoryId;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text("เพิ่มวัตถุดิบ", style: GoogleFonts.prompt(fontWeight: FontWeight.bold))),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              onChanged: (v) => setState(() => searchQuery = v),
              decoration: InputDecoration(hintText: "ค้นหาวัตถุดิบ...", prefixIcon: const Icon(Icons.search), filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
            ),
          ),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (ctx, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: ChoiceChip(
                  label: Text(categories[i]['ing_type_name'], style: GoogleFonts.prompt(color: selectedCategoryId == categories[i]['ing_type_id'] ? Colors.white : Colors.black)),
                  selected: selectedCategoryId == categories[i]['ing_type_id'],
                  onSelected: (s) => setState(() => selectedCategoryId = categories[i]['ing_type_id']),
                  selectedColor: Colors.blue,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredList.length,
              itemBuilder: (ctx, i) {
                final item = filteredList[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: ListTile(
                    leading: SizedBox(
                      width: 50, height: 50,
                      child: CachedNetworkImage(
                        imageUrl: item['ing_image'] ?? '',
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const Icon(Icons.fastfood),
                      ),
                    ),
                    title: Text(item['ing_name'] ?? '', style: GoogleFonts.prompt()),
                    subtitle: Text(_getCategoryName(item['ing_type_id']), style: GoogleFonts.prompt(fontSize: 12)),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.blue),
                      // กดปุ่มแล้วเพิ่มทันที ไม่ต้องเปิด Dialog ถามจำนวน
                      onPressed: () => _addToInventory(item['ing_id'], item['ing_name']),
                    ),
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