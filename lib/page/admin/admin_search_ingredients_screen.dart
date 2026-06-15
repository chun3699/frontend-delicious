import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../detail/ingredient_detail_screen.dart';

class AdminSearchIngredientsScreen extends StatefulWidget {
  @override
  _AdminSearchIngredientsScreenState createState() => _AdminSearchIngredientsScreenState();
}

class _AdminSearchIngredientsScreenState extends State<AdminSearchIngredientsScreen> {
  String searchQuery = "";
  String selectedCategory = "ทั้งหมด";

  final List<String> categories = ["ทั้งหมด", "เนื้อสัตว์", "ผัก", "เครื่องปรุง", "ผลไม้"];

  // ข้อมูลจำลองวัตถุดิบ
  List<Map<String, dynamic>> allIngredients = [
    {"ing_id": 1, "ing_name": "หมูสับ", "ing_category": "เนื้อสัตว์", "ing_image": "https://cdn-icons-png.flaticon.com/512/3143/3143645.png"},
    {"ing_id": 2, "ing_name": "กะหล่ำปลี", "ing_category": "ผัก", "ing_image": "https://cdn-icons-png.flaticon.com/512/2153/2153788.png"},
    {"ing_id": 3, "ing_name": "ซีอิ๊วขาว", "ing_category": "เครื่องปรุง", "ing_image": "https://cdn-icons-png.flaticon.com/512/7235/7235422.png"},
  ];

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredList = allIngredients.where((item) {
      bool matchesSearch = item['ing_name'].toString().toLowerCase().contains(searchQuery.toLowerCase());
      bool matchesCategory = selectedCategory == "ทั้งหมด" || item['ing_category'] == selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF0D47A1)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("จัดการวัตถุดิบกลาง", style: GoogleFonts.prompt(color: const Color(0xFF0D47A1), fontWeight: FontWeight.bold)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text("พบวัตถุดิบทั้งหมด ${filteredList.length} รายการ", style: GoogleFonts.prompt(fontSize: 15, color: Colors.grey[600])),
          ),
          const SizedBox(height: 15),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: "ค้นหาด้วยชื่อวัตถุดิบ...",
                hintStyle: GoogleFonts.prompt(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF1976D2)),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          const SizedBox(height: 15),

          // Category Filter
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                String category = categories[index];
                bool isSelected = selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    showCheckmark: false,
                    label: Text(
                      category,
                      style: GoogleFonts.prompt(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? const Color(0xFF0D47A1) : Colors.grey[700],
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF0D47A1).withOpacity(0.1),
                    backgroundColor: Colors.grey[100],
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onSelected: (selected) => setState(() => selectedCategory = category),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 15),

          // List View
          Expanded(
            child: filteredList.isEmpty
                ? Center(child: Text("ไม่พบข้อมูลวัตถุดิบ", style: GoogleFonts.prompt(color: Colors.grey, fontSize: 16)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 15.0),
                        child: Slidable(
                          key: ValueKey(item['ing_id']),
                          child: _buildIngredientCard(item),
                        ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, spreadRadius: 1, offset: const Offset(0, 3))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        // --- [ส่วนที่เพิ่มเข้ามาใหม่: ให้กดแล้วไปหน้ารายละเอียด] ---
        onTap: () {
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => IngredientDetailScreen(ingredient: item),
          //   ),
          // );
        },
        leading: Container(
          width: 55,
          height: 55,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFFE0F7FA), borderRadius: BorderRadius.circular(12)),
          child: CachedNetworkImage(
            imageUrl: item['ing_image'],
            placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 2),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
        ),
        title: Text(item['ing_name'], style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0D47A1))),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5.0),
          child: Text("หมวดหมู่: ${item['ing_category']}", style: GoogleFonts.prompt(fontSize: 13, color: Colors.grey[600])),
        ),
        trailing: const Icon(Icons.edit_note, color: Colors.grey),
      ),
    );
  }
}