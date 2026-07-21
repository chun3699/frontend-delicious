import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/page/detail/ingredient_detail_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;

import '/../config/config.dart';
import '/../service/auth_service.dart';
import '../search/ingredient_search_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String searchQuery = "";
  String selectedCategory = "ทั้งหมด";
  bool isLoading = true;
  List<Map<String, dynamic>> myIngredients = [];
  List<String> categories = ["ทั้งหมด"];

  @override
  void initState() {
    super.initState();
    _fetchInventory();
  }

  Future<void> _fetchInventory() async {
    setState(() => isLoading = true);
    try {
      final String? uidStr = await AuthService.getUid();
      final String? token = await AuthService.getToken();
      if (uidStr == null || token == null) return;

      final config = await Configuration.getConfig();
      final apiEndpoint = config['apiEndpoint'];

      final response = await http.get(
        Uri.parse("$apiEndpoint/uability/inventory/$uidStr"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(result['data'] ?? []);
        
        final uniqueCats = data.map((item) => item['type_name']?.toString() ?? "อื่นๆ").toSet();
        
        setState(() {
          myIngredients = data;
          categories = ["ทั้งหมด", ...uniqueCats];
        });
      }
    } catch (e) {
      debugPrint("❌ Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // 🛠️ 1. เพิ่มฟังก์ชันลบวัตถุดิบกลับเข้ามา
  Future<void> _deleteIngredient(int index, int ingId) async {
    try {
      final String? uidStr = await AuthService.getUid();
      final String? token = await AuthService.getToken();
      if (uidStr == null || token == null) return;

      final config = await Configuration.getConfig();
      final apiEndpoint = config['apiEndpoint'];

      final response = await http.delete(
        Uri.parse("$apiEndpoint/uability/remove-inventory"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"uid": int.parse(uidStr), "ing_id": ingId}),
      );

      if (response.statusCode == 200) {
        setState(() => myIngredients.removeAt(index));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบวัตถุดิบเรียบร้อยแล้ว')),
        );
      }
    } catch (e) {
      debugPrint("❌ Error deleting: $e");
    }
  }

  // 🛠️ 2. เพิ่มฟังก์ชันสลับสถานะ (มี/หมด) กลับเข้ามา
  Future<void> _toggleIngredient(int index, int ingId, int currentStatus) async {
    try {
      final String? uidStr = await AuthService.getUid();
      final String? token = await AuthService.getToken();
      final config = await Configuration.getConfig();
      final apiEndpoint = config['apiEndpoint'];

      int newStatus = currentStatus == 1 ? 0 : 1;

      final response = await http.put(
        Uri.parse("$apiEndpoint/uability/toggle-inventory"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "uid": int.parse(uidStr!),
          "ing_id": ingId,
          "status": newStatus,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          myIngredients[index]['amount'] = newStatus;
        });
      }
    } catch (e) {
      debugPrint("❌ Toggle Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredIngredients = myIngredients.where((item) {
      final nameMatches = item['ing_name'].toString().toLowerCase().contains(searchQuery.toLowerCase());
      final catMatches = selectedCategory == "ทั้งหมด" || item['type_name'] == selectedCategory;
      return nameMatches && catMatches;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("คลังวัตถุดิบของฉัน", style: GoogleFonts.prompt(fontWeight: FontWeight.bold, color: const Color(0xFF0D47A1))),
        backgroundColor: Colors.white, elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.add_circle, color: Color(0xFF00ACC1), size: 30),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (context) => const IngredientSearchScreen()));
              _fetchInventory();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(hintText: "ค้นหาวัตถุดิบ...", prefixIcon: const Icon(Icons.search, color: Color(0xFF1976D2)), filled: true, fillColor: Colors.grey[100], border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
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
                  label: Text(categories[i], style: GoogleFonts.prompt(
                    color: selectedCategory == categories[i] ? Colors.white : const Color(0xFF0D47A1),
                    fontWeight: selectedCategory == categories[i] ? FontWeight.bold : FontWeight.normal,
                  )),
                  selected: selectedCategory == categories[i],
                  onSelected: (_) => setState(() => selectedCategory = categories[i]),
                  selectedColor: const Color(0xFF00ACC1),
                  backgroundColor: Colors.blue[50],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: filteredIngredients.length,
                    itemBuilder: (context, index) {
                      final item = filteredIngredients[index];
                      
                      // 🛠️ 3. ครอบด้วย Slidable เพื่อให้สามารถเลื่อนซ้ายเพื่อกดปุ่มสลับสถานะหรือลบได้
                      return Slidable(
                        key: ValueKey(item['ing_id']),
                        endActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (_) => _toggleIngredient(
                                index,
                                item['ing_id'],
                                item['amount'],
                              ),
                              backgroundColor: item['amount'] == 1 ? Colors.orange : Colors.green,
                              foregroundColor: Colors.white,
                              icon: item['amount'] == 1 ? Icons.remove_circle : Icons.add_circle,
                              label: item['amount'] == 1 ? 'หมด' : 'มี',
                            ),
                            SlidableAction(
                              onPressed: (_) => _deleteIngredient(index, item['ing_id']),
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              icon: Icons.delete,
                              label: 'ลบ',
                            ),
                          ],
                        ),
                        child: _buildIngredientCard(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue[50]!),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(imageUrl: item['ing_image'] ?? '', width: 50, height: 50, fit: BoxFit.cover),
        ),
        title: Text(item['ing_name'] ?? 'ไม่ทราบชื่อ', style: GoogleFonts.prompt(fontWeight: FontWeight.w600, color: const Color(0xFF0D47A1))),
        subtitle: Row(
          children: [
            Icon(Icons.circle, size: 10, color: item['amount'] == 1 ? Colors.green : Colors.grey),
            const SizedBox(width: 5),
            Text(item['amount'] == 1 ? "มีวัตถุดิบ" : "หมด", style: GoogleFonts.prompt(color: Colors.grey[600])),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => IngredientDetailScreen(ingredientId: item['ing_id']))),
      ),
    );
  }
}