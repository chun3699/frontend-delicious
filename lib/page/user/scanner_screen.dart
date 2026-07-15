import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/config/config.dart';
import 'package:flutter_application_1/service/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import '../detail/ingredient_detail_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  File? _image;
  String _predictionResult = "";
  Map<String, dynamic>? _detectedIngredient;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _predictionResult = "กำลังวิเคราะห์...";
          _detectedIngredient = null;
        });
        _uploadImageToAI(_image!);
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<void> _uploadImageToAI(File imageFile) async {
    setState(() => _isLoading = true);
    try {
      var uri = Uri.parse(
        'https://chun111-delicious-food-api.hf.space/api/predict',
      );
      var request = http.MultipartRequest('POST', uri);
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );
      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var json = jsonDecode(responseData);
        if (json['status'] == 'success') {
          String ingredientName = json['ingredient'];

          // ✅ เพิ่มการเช็คว่าชื่อที่ได้มาจาก AI คือ "ไม่ทราบ" หรือไม่
          if (ingredientName == "ไม่ทราบ") {
            setState(() {
              _predictionResult = "ไม่ทราบ"; // แสดงข้อความ "ไม่ทราบ" บนหน้าจอ
              _detectedIngredient =
                  null; // ล้างข้อมูลเก่าออก เพื่อไม่ให้ปุ่มต่างๆ แสดงขึ้นมา
            });
          } else {
            // กรณีระบุชื่อได้ปกติ
            setState(() => _predictionResult = "วิเคราะห์สำเร็จ");
            await _fetchIngredientDetails(ingredientName);
          }
        } else {
          setState(() => _predictionResult = "ไม่สามารถระบุวัตถุดิบได้");
          _detectedIngredient = null;
        }
      } else {
        setState(
          () => _predictionResult =
              "ไม่สามารถวิเคราะห์ได้ (Error ${response.statusCode})",
        );
        _detectedIngredient = null;
      }
    } catch (error) {
      setState(() => _predictionResult = "ไม่สามารถเชื่อมต่อ AI ได้");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchIngredientDetails(String name) async {
    final config = await Configuration.getConfig();
    final token = await AuthService.getToken();
    try {
      final response = await http.get(
        Uri.parse("${config['apiEndpoint']}/ingredient/search/name?name=$name"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );
      if (response.statusCode == 200) {
        setState(() => _detectedIngredient = jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint("Detail Error: $e");
    }
  }

  // ปรับการเพิ่มคลัง: ส่งค่า amount เป็น 1 เสมอ
  Future<void> _addToInventory(int ingId, String ingName) async {
    try {
      final String? uidStr = await AuthService.getUid();
      final String? token = await AuthService.getToken();
      final config = await Configuration.getConfig();
      final apiEndpoint = config['apiEndpoint'];

      final response = await http.post(
        Uri.parse("$apiEndpoint/uability/add-inventory"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "uid": int.parse(uidStr!),
          "ing_id": ingId,
          "amount": 1,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'เพิ่ม $ingName เข้าคลังเรียบร้อย!',
              style: GoogleFonts.prompt(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final result = jsonDecode(response.body);
        _showSnackBar(result['message'] ?? 'มีวัตถุดิบนี้ในคลังแล้ว');
      }
    } catch (e) {
      _showSnackBar("เกิดข้อผิดพลาดในการเชื่อมต่อ");
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.prompt()),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "สแกนวัตถุดิบ",
          style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              height: 300,
              width: 300,
              color: Colors.grey[200],
              child: _image != null
                  ? Image.file(_image!, fit: BoxFit.cover)
                  : const Icon(Icons.camera_alt, size: 80),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                "⚠️ หมายเหตุ: AI อาจวิเคราะห์ผลลัพธ์ไม่ถูกต้อง โปรดตรวจสอบข้อมูลอีกครั้ง",
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),

            if (_isLoading) const CircularProgressIndicator(),

            if (!_isLoading && _predictionResult.isNotEmpty) ...[
              Text(
                _predictionResult,
                style: GoogleFonts.prompt(fontSize: 18, color: Colors.blue),
              ),
              if (_detectedIngredient != null) ...[
                const SizedBox(height: 10),
                // ✅ เพิ่ม: แสดงชื่อภาษาอังกฤษ (ing_name)
                Text(
                  "ชื่อ (ENG): ${_detectedIngredient!['ing_name'] ?? 'ไม่มีข้อมูล'}",
                  style: GoogleFonts.prompt(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey,
                  ),
                ),
                Text(
                  "ชื่อไทย: ${_detectedIngredient!['ing_thai_name'] ?? 'ไม่มีข้อมูล'}",
                  style: GoogleFonts.prompt(fontSize: 16),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => IngredientDetailScreen(
                            // ส่งเฉพาะค่า ID ที่เป็นตัวเลข (int) เข้าไปตามที่หน้า Detail ต้องการ
                            ingredientId: _detectedIngredient!['ing_id'],
                          ),
                        ),
                      ),
                      child: Text("ดูรายละเอียด", style: GoogleFonts.prompt()),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () => _addToInventory(
                        _detectedIngredient!['ing_id'],
                        _detectedIngredient!['ing_name'],
                      ),
                      child: Text(
                        "เพิ่มเข้าคลัง",
                        style: GoogleFonts.prompt(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ],

            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: Text("กล้อง", style: GoogleFonts.prompt()),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: Text("อัลบั้ม", style: GoogleFonts.prompt()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
