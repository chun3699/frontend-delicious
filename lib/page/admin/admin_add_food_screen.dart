import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminAddFoodScreen extends StatefulWidget {
  const AdminAddFoodScreen ({super.key});
  @override
  State<AdminAddFoodScreen> createState() => _AdminAddFoodScreenState();
 
}

class _AdminAddFoodScreenState extends State<AdminAddFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controller สำหรับข้อมูลหลัก
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  // รายการไดนามิกสำหรับ "วิธีการปรุง" และ "ตารางวัตถุดิบ"
  List<TextEditingController> _stepControllers = [TextEditingController()];
  List<Map<String, TextEditingController>> _ingredientControllers = [
    {
      "name": TextEditingController(),
      "amount": TextEditingController(),
    }
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    for (var controller in _stepControllers) {
      controller.dispose();
    }
    for (var row in _ingredientControllers) {
      row['name']?.dispose();
      row['amount']?.dispose();
    }
    super.dispose();
  }

  // ฟังก์ชันเพิ่มขั้นตอนการปรุง
  void _addStep() {
    setState(() {
      _stepControllers.add(TextEditingController());
    });
  }

  // ฟังก์ชันลบขั้นตอนการปรุง
  void _removeStep(int index) {
    if (_stepControllers.length > 1) {
      setState(() {
        _stepControllers[index].dispose();
        _stepControllers.removeAt(index);
      });
    }
  }

  // ฟังก์ชันเพิ่มแถววัตถุดิบ
  void _addIngredientRow() {
    setState(() {
      _ingredientControllers.add({
        "name": TextEditingController(),
        "amount": TextEditingController(),
      });
    });
  }

  // ฟังก์ชันลบแถววัตถุดิบ
  void _removeIngredientRow(int index) {
    if (_ingredientControllers.length > 1) {
      setState(() {
        _ingredientControllers[index]['name']?.dispose();
        _ingredientControllers[index]['amount']?.dispose();
        _ingredientControllers.removeAt(index);
      });
    }
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
          "เพิ่มเมนูอาหารใหม่",
          style: GoogleFonts.prompt(color: const Color(0xFF0D47A1), fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. ส่วนอัปโหลดรูปภาพเมนูอาหาร
              Text("รูปภาพเมนูอาหาร", style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  // TODO: เชื่อมต่อ Image Picker เพื่อเลือกรูปภาพและอัปโหลดไป Cloudinary
                },
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F7FA).withOpacity(0.4),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: const Color(0xFF00ACC1).withOpacity(0.5), style: BorderStyle.solid),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_a_photo_rounded, size: 40, color: Color(0xFF00ACC1)),
                      const SizedBox(height: 8),
                      Text("คลิกเพื่อเลือกรูปภาพอาหาร", style: GoogleFonts.prompt(color: const Color(0xFF0D47A1), fontSize: 14)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // 2. ข้อมูลทั่วไป (ชื่อและเนื้อหา)
              _buildLabel("ชื่อเมนูอาหาร"),
              TextFormField(
                controller: _nameController,
                validator: (value) => value!.isEmpty ? 'กรุณากรอกชื่อเมนู' : null,
                decoration: _buildInputDecoration("ตัวอย่าง: ต้มยำกุ้งน้ำข้น"),
              ),
              const SizedBox(height: 20),

              _buildLabel("เนื้อหา / คำอธิบายเมนู"),
              TextFormField(
                controller: _contentController,
                maxLines: 3,
                validator: (value) => value!.isEmpty ? 'กรุณากรอกคำอธิบาย' : null,
                decoration: _buildInputDecoration("อธิบายจุดเด่นของเมนูนี้สั้นๆ..."),
              ),
              const SizedBox(height: 25),

              // 3. ส่วนการจัดการตารางวัตถุดิบ
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLabel("ตารางวัตถุดิบที่ต้องใช้"),
                  TextButton.icon(
                    onPressed: _addIngredientRow,
                    icon: const Icon(Icons.add, size: 18, color: Color(0xFF00ACC1)),
                    label: Text("เพิ่มวัตถุดิบ", style: GoogleFonts.prompt(color: const Color(0xFF00ACC1))),
                  )
                ],
              ),
              const SizedBox(height: 5),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _ingredientControllers.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _ingredientControllers[index]['name'],
                            decoration: _buildInputDecoration("ชื่อวัตถุดิบ"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _ingredientControllers[index]['amount'],
                            decoration: _buildInputDecoration("ปริมาณ (เช่น 200 กรัม)"),
                          ),
                        ),
                        if (_ingredientControllers.length > 1)
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                            onPressed: () => _removeIngredientRow(index),
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 25),

              // 4. ส่วนวิธีการปรุง (Dynamic Steps)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLabel("วิธีการปรุง"),
                  TextButton.icon(
                    onPressed: _addStep,
                    icon: const Icon(Icons.add, size: 18, color: Color(0xFF00ACC1)),
                    label: Text("เพิ่มขั้นตอน", style: GoogleFonts.prompt(color: const Color(0xFF00ACC1))),
                  )
                ],
              ),
              const SizedBox(height: 5),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _stepControllers.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: const Color(0xFF0D47A1),
                          child: Text("${index + 1}", style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: TextFormField(
                            controller: _stepControllers[index],
                            decoration: _buildInputDecoration("ขั้นตอนที่ ${index + 1}..."),
                          ),
                        ),
                        if (_stepControllers.length > 1)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _removeStep(index),
                          ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),

              // 5. ปุ่มบันทึกข้อมูลทั้งหมด
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1), // Navy Blue
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // TODO: ดึงข้อมูลจาก Controller ทั้งหมดส่งไปยัง Node.js Backend API
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("บันทึกเมนูอาหารสำเร็จ", style: GoogleFonts.prompt())),
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: Text(
                    "บันทึกเมนูอาหาร",
                    style: GoogleFonts.prompt(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Helper ฟังก์ชันสำหรับสร้าง Label ข้อความหัวข้อ
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87)),
    );
  }

  // Helper ฟังก์ชันสำหรับสร้างสไตล์ให้กับช่องกรอกข้อความ (Input Decoration)
  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.prompt(color: Colors.grey[400], fontSize: 14),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF00ACC1)),
      ),
    );
  }
}