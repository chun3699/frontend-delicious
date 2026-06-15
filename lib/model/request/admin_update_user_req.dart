import 'dart:convert';

AdminUpdateUserReq adminUpdateUserReqFromJson(String str) => AdminUpdateUserReq.fromJson(json.decode(str));

String adminUpdateUserReqToJson(AdminUpdateUserReq data) => json.encode(data.toJson());

class AdminUpdateUserReq {
    String uName;
    String uEmail;
    String? uPassword; // 1. เติมเครื่องหมาย ? เพื่อบอกว่าเป็นค่าว่าง (null) ได้
    String uRole;
    String uProfile;

    AdminUpdateUserReq({
        required this.uName,
        required this.uEmail,
        this.uPassword,    // 2. เอาคำว่า required ออก เพราะรหัสผ่านไม่จำเป็นต้องส่งมาเสมอ
        required this.uRole,
        required this.uProfile,
    });

    factory AdminUpdateUserReq.fromJson(Map<String, dynamic> json) => AdminUpdateUserReq(
        uName: json["u_name"],
        uEmail: json["u_email"],
        uPassword: json["u_password"],
        uRole: json["u_role"],
        uProfile: json["u_profile"],
    );

    Map<String, dynamic> toJson() {
        // 3. จัดการคัดกรองข้อมูลก่อนส่งไปแปลงเป็น JSON
        Map<String, dynamic> data = {
            "u_name": uName,
            "u_email": uEmail,
            "u_role": uRole,
            "u_profile": uProfile,
        };

        // ถ้ามีการพิมพ์รหัสผ่านใหม่มา ค่อยเพิ่มคีย์ u_password เข้าไปส่งให้ Backend
        if (uPassword != null && uPassword!.isNotEmpty) {
            data["u_password"] = uPassword;
        }

        return data;
    }
}