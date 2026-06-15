import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;

// Import ส่วนของ Config และ Service
import '../../config/config.dart';
import '../../service/auth_service.dart';

// ⭐️ Import โมเดล IngredientRes เข้ามาใช้งาน (เช็ค Path ให้ตรงกับโครงสร้างโฟลเดอร์ของคุณ)
import '../../model/request/response/ingredient_res.dart'; 

class IngredientDetailScreen extends StatefulWidget {
  final int ingredientId; 

  const IngredientDetailScreen({Key? key, required this.ingredientId}) : super(key: key);

  @override
  State<IngredientDetailScreen> createState() => _IngredientDetailScreenState();
}

class _IngredientDetailScreenState extends State<IngredientDetailScreen> {
  // ⭐️ เปลี่ยนชนิดตัวแปรจาก Map เป็น โมเดล IngredientRes
  IngredientRes? ingredient; 
  bool _isLoading = true; 

  // (Optional) ตัวแปรสำหรับเก็บชื่อหมวดหมู่ที่แปลจาก ingTypeId มาแล้ว (ถ้ามี API รองรับ)
  String categoryName = "กำลังดึงข้อมูลหมวดหมู่...";

  @override
  void initState() {
    super.initState();
    _fetchIngredientDetail(); 
  }

  // ==========================================
  // 🌐 API: ฟังก์ชันดึงรายละเอียดวัตถุดิบ
  // ==========================================
  Future<void> _fetchIngredientDetail() async {
    try {
      final config = await Configuration.getConfig();
      final apiEndpoint = config['apiEndpoint'];
      final String? token = await AuthService.getToken();

      final response = await http.get(
        Uri.parse("$apiEndpoint/ingredient/${widget.ingredientId}"), 
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        // ในกรณีที่ API ส่งกลับมาเป็น List ของ Object เช่น [{...}]
        // เราต้องดึง Object ตัวแรก [0] ออกมาก่อนแปลงเป็น Model
        final dynamic jsonData = jsonDecode(response.body);
        final Map<String, dynamic> data = (jsonData is List) ? jsonData[0] : jsonData;
        
        setState(() {
          // ⭐️ แปลง JSON ที่ได้เป็น Model IngredientRes
          ingredient = IngredientRes.fromJson(data);
          
        
          categoryName = "ประเภทวัตถุดิบ : ${ingredient!.ingTypeName}";
          
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _showSnackBar("ไม่สามารถดึงข้อมูลรายละเอียดวัตถุดิบได้");
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("การเชื่อมต่อเซิร์ฟเวอร์ผิดพลาด: $e");
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: GoogleFonts.prompt()), backgroundColor: Colors.red),
    );
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
          "รายละเอียดวัตถุดิบ",
          style: GoogleFonts.prompt(color: const Color(0xFF0D47A1), fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ingredient == null
              ? Center(child: Text("ไม่พบข้อมูลวัตถุดิบชิ้นนี้", style: GoogleFonts.prompt(color: Colors.grey)))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. ส่วนแสดงรูปภาพวัตถุดิบ
                      Container(
                        width: double.infinity,
                        height: 300,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F7FA),
                          // ⭐️ ดึงค่าจาก Model (ingredient!.ingImage)
                          image: ingredient!.ingImage != "-" && ingredient!.ingImage.isNotEmpty
                              ? DecorationImage(
                                  image: CachedNetworkImageProvider(ingredient!.ingImage),
                                  fit: BoxFit.contain,
                                )
                              : null,
                        ),
                        child: ingredient!.ingImage == "-" || ingredient!.ingImage.isEmpty
                            ? const Icon(Icons.fastfood, size: 80, color: Colors.grey)
                            : null,
                      ),

                      Padding(
                        padding: const EdgeInsets.all(25.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 2. หมวดหมู่ (ดึงจากตัวแปร categoryName ที่เตรียมไว้)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00ACC1).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                categoryName,
                                style: GoogleFonts.prompt(color: const Color(0xFF00ACC1), fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(height: 15),

                            // 3. ชื่อวัตถุดิบ
                            Text(
                              ingredient!.ingName, // ⭐️ ดึงค่าจาก Model
                              style: GoogleFonts.prompt(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0D47A1),
                              ),
                            ),
                            const Divider(height: 40, thickness: 1),

                            // 4. รายละเอียด
                            Text(
                              "ข้อมูลเพิ่มเติม:",
                              style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              ingredient!.ingDetail, // ⭐️ ดึงค่าจาก Model
                              style: GoogleFonts.prompt(fontSize: 16, color: Colors.grey[700], height: 1.6),
                            ),

                            const SizedBox(height: 50),

                            
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}