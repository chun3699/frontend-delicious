import 'dart:convert';
import 'package:flutter/material.dart';
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
  bool isLoading = true;
  List<Map<String, dynamic>> myIngredients = [];

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

      if (uidStr == null || token == null) {
        _showError("กรุณาเข้าสู่ระบบก่อนใช้งาน");
        return;
      }

      final config = await Configuration.getConfig();
      final apiEndpoint = config['apiEndpoint'];

      final response = await http.get(
        Uri.parse("$apiEndpoint/uability/inventory/$uidStr"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        setState(() {
          myIngredients = List<Map<String, dynamic>>.from(result['data'] ?? []);
        });
      } else {
        _showError("ไม่สามารถดึงข้อมูลได้ (Code: ${response.statusCode})");
      }
    } catch (e) {
      debugPrint("❌ Error fetching inventory: $e");
      _showError("เกิดข้อผิดพลาดในการเชื่อมต่อ");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ลบวัตถุดิบเรียบร้อยแล้ว')));
      }
    } catch (e) {
      debugPrint("❌ Error deleting: $e");
    }
  }

  // ฟังก์ชันใหม่: ใช้สลับสถานะ มี (1) / หมด (0)
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
        body: jsonEncode({"uid": int.parse(uidStr!), "ing_id": ingId, "status": newStatus}),
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

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: GoogleFonts.prompt()), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredIngredients = myIngredients.where((item) {
      return item['ing_name'].toString().toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("คลังวัตถุดิบของฉัน", style: GoogleFonts.prompt(color: const Color(0xFF0D47A1), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Color(0xFF00ACC1), size: 30),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (context) => const IngredientSearchScreen()));
              _fetchInventory(); 
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: "ค้นหาวัตถุดิบ...",
                prefixIcon: const Icon(Icons.search, color: Color(0xFF1976D2)),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: filteredIngredients.length,
                      itemBuilder: (context, index) {
                        final item = filteredIngredients[index];
                        return Slidable(
                          key: ValueKey(item['ing_id']),
                          endActionPane: ActionPane(
                            motion: const ScrollMotion(),
                            children: [
                              SlidableAction(
                                onPressed: (_) => _toggleIngredient(index, item['ing_id'], item['amount']),
                                backgroundColor: item['amount'] == 1 ? Colors.orange : Colors.green,
                                icon: item['amount'] == 1 ? Icons.remove_circle : Icons.add_circle,
                                label: item['amount'] == 1 ? 'หมด' : 'มี',
                              ),
                              SlidableAction(
                                onPressed: (_) => _deleteIngredient(index, item['ing_id']),
                                backgroundColor: Colors.redAccent,
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
      ),
    );
  }

  Widget _buildIngredientCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: ListTile(
        leading: Container(
          width: 60, height: 60, padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFFE0F7FA), borderRadius: BorderRadius.circular(12)),
          child: CachedNetworkImage(imageUrl: item['ing_image'] ?? '', errorWidget: (_, __, ___) => const Icon(Icons.fastfood)),
        ),
        title: Text(item['ing_name'] ?? 'ไม่ทราบชื่อ', style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.w500, color: const Color(0xFF0D47A1))),
        subtitle: Text(
          item['amount'] == 1 ? "สถานะ: มีวัตถุดิบ" : "สถานะ: หมด",
          style: GoogleFonts.prompt(fontSize: 14, fontWeight: FontWeight.bold, color: item['amount'] == 1 ? Colors.green : Colors.grey),
        ),
      ),
    );
  }
}