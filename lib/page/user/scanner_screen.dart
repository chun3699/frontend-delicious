import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/config/config.dart';
import 'package:flutter_application_1/service/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  File? _image;
  String _predictionResult = "";
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
          _predictionResult = "";
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
        setState(() {
          if (json['status'] == 'success') {
            String ingredientName = json['ingredient'];
            String capitalizedName =
                "${ingredientName[0].toUpperCase()}${ingredientName.substring(1)}";
            _predictionResult =
                "นี่คือ: $capitalizedName\nความแม่นยำ: ${(json['confidence'] * 100).toStringAsFixed(2)}%";
          } else {
            _predictionResult = "เซิร์ฟเวอร์ตอบกลับแต่สถานะไม่สำเร็จ";
          }
        });
      } else {
        setState(
          () => _predictionResult =
              "ไม่สามารถวิเคราะห์ได้ (Error ${response.statusCode})",
        );
      }
    } catch (error) {
      setState(
        () =>
            _predictionResult = "ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ AI ได้\n$error",
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addToInventory(int ingId, String ingName, int amount) async {
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
          "amount": amount,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'เพิ่ม $ingName จำนวน $amount เรียบร้อย!',
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
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: _image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(_image!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_search,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          Text(
                            "ยังไม่ได้เลือกรูปภาพ",
                            style: GoogleFonts.prompt(color: Colors.grey),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 30),
              if (_isLoading)
                const CircularProgressIndicator()
              else if (_predictionResult.isNotEmpty &&
                  !_predictionResult.contains("Error"))
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Text(
                        _predictionResult,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.prompt(
                          fontSize: 18,
                          color: Colors.blue[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final String? token = await AuthService.getToken();
                        // 1. สกัดชื่อและทำความสะอาดให้เหลือแต่ตัวอักษรภาษาอังกฤษ
                        String rawName = _predictionResult
                            .split(": ")[1]
                            .split("\n")[0];
                        String ingredientName = rawName
                            .replaceAll(RegExp(r'[^a-zA-Z]'), '')
                            .toLowerCase();

                        print("DEBUG: กำลังค้นหาชื่อ '$ingredientName'");

                        // 2. เรียก API เพื่อค้นหา ID
                        final config = await Configuration.getConfig();
                        // 2. ส่ง Header 'Authorization' ไปด้วยใน http.get
                        final response = await http.get(
                          Uri.parse(
                            "${config['apiEndpoint']}/ingredient/search/name?name=$ingredientName",
                          ),
                          headers: {
                            "Authorization":
                                "Bearer $token", // <--- เพิ่มบรรทัดนี้
                            "Content-Type": "application/json",
                          },
                        );

                        print(
                          "DEBUG: Response Status: ${response.statusCode}, Body: ${response.body}",
                        );

                        if (response.statusCode == 200) {
                          final data = jsonDecode(response.body);
                          int ingId = data['ing_id'];

                          // 3. แสดง Dialog รับค่าจำนวน
                          final TextEditingController ctrl =
                              TextEditingController();
                          String? amount = await showDialog<String>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text(
                                "ระบุจำนวน",
                                style: GoogleFonts.prompt(),
                              ),
                              content: TextField(
                                controller: ctrl,
                                keyboardType: TextInputType.number,
                                autofocus: true,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text("ยกเลิก"),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    final int? val = int.tryParse(ctrl.text);
                                    // ตรวจสอบว่าต้องเป็นตัวเลข และต้องมากกว่า 0 เท่านั้น
                                    if (val != null && val > 0) {
                                      Navigator.pop(ctx, ctrl.text);
                                    } else {
                                      // ถ้ากรอกไม่ผ่าน ให้แสดง SnackBar เตือน
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "กรุณาระบุจำนวนมากกว่า 0",
                                            style: GoogleFonts.prompt(),
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                                  child: Text("ตกลง"),
                                ),
                              ],
                            ),
                          );

                          // 4. ส่งไปบันทึกถ้าได้ค่าจำนวนแล้ว
                          if (amount != null && amount.isNotEmpty) {
                            await _addToInventory(
                              ingId,
                              ingredientName,
                              int.parse(amount),
                            );
                          }
                        } else {
                          _showSnackBar(
                            "ไม่พบวัตถุดิบ '$ingredientName' ในฐานข้อมูล",
                          );
                        }
                      },
                      icon: const Icon(Icons.add_shopping_cart),
                      label: Text(
                        "เพิ่มวัตถุดิบนี้เข้าคลัง",
                        style: GoogleFonts.prompt(),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00ACC1),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: Text("เปิดกล้อง", style: GoogleFonts.prompt()),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: Text("เลือกรูปภาพ", style: GoogleFonts.prompt()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
