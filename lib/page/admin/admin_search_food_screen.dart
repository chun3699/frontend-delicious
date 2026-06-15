import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'admin_add_food_screen.dart'; // โยงไปหน้าเพิ่มอาหาร
import 'admin_edit_food_screen.dart';

class AdminSearchFoodScreen extends StatefulWidget {
  const AdminSearchFoodScreen({super.key});
  @override
  _AdminSearchFoodScreenState createState() => _AdminSearchFoodScreenState();
}

class _AdminSearchFoodScreenState extends State<AdminSearchFoodScreen> {
  String searchQuery = "";
  String selectedCategory = "ทั้งหมด";

  final List<String> categories = ["ทั้งหมด", "ต้ม", "ผัด", "แกง", "ทอด"];

  // ข้อมูลจำลองอาหาร (อิงตามโมเดลของคุณ)
  List<Map<String, dynamic>> allFoods = [
    {
      "id": 1,
      "name": "กะเพราหมูสับ",
      "category": "ผัด",
      "imageUrl": "https://images.unsplash.com/photo-1626804475297-41609ea004eb?w=500",
      "ingredients_count": 5
    },
    {
      "id": 2,
      "name": "ต้มยำกุ้ง",
      "category": "ต้ม",
      "imageUrl": "https://images.unsplash.com/photo-1548943487-a2e4f43b4850?w=500",
      "ingredients_count": 8
    },
    {
      "id": 3,
      "name": "ไก่ทอดกระเทียม",
      "category": "ทอด",
      "imageUrl": "https://images.unsplash.com/photo-1626645738196-c2a7c87a8f58?w=500",
      "ingredients_count": 4
    },
  ];

  // ฟังก์ชันแสดงหน้าต่างยืนยันการลบ
  void _confirmDeleteFood(int index, Map<String, dynamic> food) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text("ยืนยันการลบ?", style: GoogleFonts.prompt(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text("คุณต้องการลบเมนู '${food['name']}' ใช่หรือไม่?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("ยกเลิก", style: GoogleFonts.prompt(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() => allFoods.removeWhere((element) => element['id'] == food['id']));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("ลบเมนูอาหารสำเร็จ")));
            },
            child: Text("ลบเมนู", style: GoogleFonts.prompt(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredFoods = allFoods.where((food) {
      bool matchesSearch = food['name'].toString().toLowerCase().contains(searchQuery.toLowerCase());
      bool matchesCategory = selectedCategory == "ทั้งหมด" || food['category'] == selectedCategory;
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
        title: Text("จัดการเมนูอาหาร", style: GoogleFonts.prompt(color: const Color(0xFF0D47A1), fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: Color(0xFF00ACC1), size: 28),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdminAddFoodScreen())),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text("พบเมนูอาหารทั้งหมด ${filteredFoods.length} รายการ", style: GoogleFonts.prompt(fontSize: 15, color: Colors.grey[600])),
          ),
          const SizedBox(height: 15),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: "ค้นหาด้วยชื่อเมนูอาหาร...",
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
                        color: isSelected ? const Color(0xFF00ACC1) : Colors.grey[700],
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF00ACC1).withOpacity(0.1),
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
            child: filteredFoods.isEmpty
                ? Center(child: Text("ไม่พบเมนูอาหาร", style: GoogleFonts.prompt(color: Colors.grey, fontSize: 16)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: filteredFoods.length,
                    itemBuilder: (context, index) {
                      final food = filteredFoods[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 15.0),
                        child: Slidable(
                          key: ValueKey(food['id']),
                          endActionPane: ActionPane(
                            motion: const ScrollMotion(),
                            children: [
                              SlidableAction(
                                onPressed: (context) {                            
                                  // --- [แก้ไขโค้ดตรงนี้เพื่อนำทางไปหน้าแก้ไข] ---
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AdminEditFoodScreen(foodData: food),
                                    ),
                                  );
                                },
                                backgroundColor: const Color(0xFFF4A261),
                                foregroundColor: Colors.white,
                                icon: Icons.edit,
                                label: 'แก้ไข',
                              ),
                              SlidableAction(
                                onPressed: (context) => _confirmDeleteFood(index, food),
                                backgroundColor: const Color(0xFFFE4A49),
                                foregroundColor: Colors.white,
                                icon: Icons.delete,
                                label: 'ลบ',
                                borderRadius: const BorderRadius.only(topRight: Radius.circular(15), bottomRight: Radius.circular(15)),
                              ),
                            ],
                          ),
                          child: _buildFoodCard(food),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodCard(Map<String, dynamic> food) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, spreadRadius: 1, offset: const Offset(0, 3))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedNetworkImage(
            imageUrl: food['imageUrl'],
            width: 65,
            height: 65,
            fit: BoxFit.cover,
            placeholder: (context, url) => const CircularProgressIndicator(),
            errorWidget: (context, url, error) => const Icon(Icons.fastfood, color: Colors.grey),
          ),
        ),
        title: Text(food['name'], style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0D47A1))),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5.0),
          child: Text("หมวดหมู่: ${food['category']} • วัตถุดิบ ${food['ingredients_count']} อย่าง", style: GoogleFonts.prompt(fontSize: 13, color: Colors.grey[600])),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      ),
    );
  }
}