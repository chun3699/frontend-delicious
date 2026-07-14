import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

class IngredientDetailScreen extends StatelessWidget {
  final Map<String, dynamic> ingredient;

  // รับค่า object วัตถุดิบผ่าน Constructor
  const IngredientDetailScreen({super.key, required this.ingredient});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("รายละเอียดวัตถุดิบ", style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.blue),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ส่วนแสดงรูปภาพขนาดใหญ่
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CachedNetworkImage(
                  imageUrl: ingredient['ing_image'] ?? '',
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    height: 250, color: Colors.grey[200], child: const Icon(Icons.fastfood, size: 80),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 25),
            
            // ชื่อวัตถุดิบ
            Text(
              ingredient['ing_name'] ?? 'ไม่มีชื่อ',
              style: GoogleFonts.prompt(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF0D47A1)),
            ),
            const SizedBox(height: 10),
            
            // ประเภทวัตถุดิบ (ใช้ค่าที่มีจากฐานข้อมูล)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10)),
              child: Text(
                "ประเภท: ${ingredient['ing_type_id'] ?? 'ไม่ระบุ'}", // สามารถเปลี่ยนเป็นชื่อประเภทถ้าดึงมาได้
                style: GoogleFonts.prompt(fontSize: 14, color: Colors.blue[800]),
              ),
            ),
            const SizedBox(height: 20),
            
            // รายละเอียด
            Text(
              "รายละเอียด:",
              style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              ingredient['ing_detail'] ?? "ไม่มีข้อมูลรายละเอียดสำหรับวัตถุดิบนี้",
              style: GoogleFonts.prompt(fontSize: 16, color: Colors.grey[700], height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}