import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AdminEditFoodScreen extends StatefulWidget {
  final Map<String, dynamic> foodData;

  const AdminEditFoodScreen({Key? key, required this.foodData}) : super(key: key);

  @override
  _AdminEditFoodScreenState createState() => _AdminEditFoodScreenState();
}

class _AdminEditFoodScreenState extends State<AdminEditFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _contentController;
  late String selectedCategory;

  final List<String> categories = ["ต้ม", "ผัด", "แกง", "ทอด"];

  // รายการสำหรับ "วิธีการปรุง" และ "ตารางวัตถุดิบ"
  List<TextEditingController> _stepControllers = [];
  List<Map<String, TextEditingController>> _ingredientControllers = [];

  @override
  void initState() {
    super.initState();
    
    // 1. ดึงข้อมูลเดิมจาก widget.foodData มาใส่ใน Controller
    _nameController = TextEditingController(text: widget.foodData['name'] ?? '');
    _contentController = TextEditingController(
      text: widget.foodData['content'] ?? 'เมนูอาหารอร่อยทำง่าย ได้ประโยชน์สูง (ข้อมูลจำลอง)',
    );
    selectedCategory = categories.contains(widget.foodData['category']) 
        ? widget.foodData['category'] 
        : 'ผัด';

    // 2. ดึงข้อมูลตารางวัตถุดิบเดิม (ถ้าไม่มี ให้สร้างข้อมูลจำลองไว้แสดงผล)
    if (widget.foodData['ingredients'] != null) {
      _ingredientControllers = (widget.foodData['ingredients'] as List).map((ing) {
        return {
          "name": TextEditingController(text: ing['name']?.toString()),
          "amount": TextEditingController(text: ing['amount']?.toString()),
        };
      }).toList();
    } else {
      _ingredientControllers = [
        {"name": TextEditingController(text: "หมูสับ"), "amount": TextEditingController(text: "200 กรัม")},
        {"name": TextEditingController(text: "ใบกะเพรา"), "amount": TextEditingController(text: "1 กำ")},
      ];
    }

    // 3. ดึงข้อมูลขั้นตอนการปรุงเดิม
    if (widget.foodData['steps'] != null) {
      _stepControllers = (widget.foodData['steps'] as List).map((step) {
        return TextEditingController(text: step.toString());
      }).toList();
    } else {
      _stepControllers = [
        TextEditingController(text: "ตั้งกระทะให้ร้อน ใส่น้ำมัน กระเทียม และพริกสับลงไปผัดจนเหลืองหอม"),
        TextEditingController(text: "ใส่เนื้อสัตว์ลงไปผัดจนสุก ปรุงรสตามชอบ จากนั้นใส่ใบกะเพราแล้วปิดไฟ"),
      ];
    }
  }

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

  void _addStep() {
    setState(() => _stepControllers.add(TextEditingController()));
  }

  void _removeStep(int index) {
    if (_stepControllers.length > 1) {
      setState(() {
        _stepControllers[index].dispose();
        _stepControllers.removeAt(index);
      });
    }
  }

  void _addIngredientRow() {
    setState(() {
      _ingredientControllers.add({
        "name": TextEditingController(),
        "amount": TextEditingController(),
      });
    });
  }

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
          "แก้ไขเมนูอาหาร",
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
              // 1. ส่วนแสดงรูปภาพเดิม / อัปโหลดใหม่
              Text("รูปภาพเมนูอาหารปัจจุบัน", style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  // TODO: เปลี่ยนรูปภาพใหม่และส่งไป Cloudinary
                },
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(15),
                    image: widget.foodData['imageUrl'] != null 
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(widget.foodData['imageUrl']),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.camera_enhance_rounded, size: 35, color: Colors.white),
                          const SizedBox(height: 5),
                          Text("กดเพื่อเปลี่ยนรูปภาพอาหาร", style: GoogleFonts.prompt(color: Colors.white, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // 2. ข้อมูลทั่วไป
              _buildLabel("ชื่อเมนูอาหาร"),
              TextFormField(
                controller: _nameController,
                validator: (value) => value!.isEmpty ? 'กรุณากรอกชื่อเมนู' : null,
                decoration: _buildInputDecoration("ชื่อเมนูอาหาร"),
              ),
              const SizedBox(height: 20),

              // หมวดหมู่ (Dropdown)
              _buildLabel("ประเภทอาหาร"),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedCategory,
                    items: categories.map((String cat) {
                      return DropdownMenuItem<String>(
                        value: cat,
                        child: Text(cat, style: GoogleFonts.prompt()),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedCategory = newValue!;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              _buildLabel("เนื้อหา / คำอธิบายเมนู"),
              TextFormField(
                controller: _contentController,
                maxLines: 3,
                validator: (value) => value!.isEmpty ? 'กรุณากรอกคำอธิบาย' : null,
                decoration: _buildInputDecoration("คำอธิบายเมนูอาหาร..."),
              ),
              const SizedBox(height: 25),

              // 3. ตารางวัตถุดิบ
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
                            decoration: _buildInputDecoration("ปริมาณ"),
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

              // 4. วิธีการปรุง
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
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _stepControllers.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
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

              // 5. ปุ่มบันทึกการเปลี่ยนแปลง
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00ACC1), // สี Cyan บ่งบอกถึงการอัปเดต/แก้ไข
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // TODO: ส่งข้อมูลที่แก้ไขแล้วไปยัง Node.js Backend API เพื่ออัปเดต MySQL
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("อัปเดตข้อมูลเมนูอาหารเรียบร้อยแล้ว", style: GoogleFonts.prompt())),
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: Text(
                    "บันทึกการเปลี่ยนแปลง",
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8.0),
      child: Text(text, style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87)),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.prompt(color: Colors.grey[400], fontSize: 14),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00ACC1))),
    );
  }
}