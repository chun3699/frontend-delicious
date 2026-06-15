import 'dart:convert';

UserResgisterPostReq userResgisterPostReqFromJson(String str) => UserResgisterPostReq.fromJson(json.decode(str));

String userResgisterPostReqToJson(UserResgisterPostReq data) => json.encode(data.toJson());

class UserResgisterPostReq {
    String uName;
    String uEmail; // เพิ่มช่องอีเมล
    String uPassword;
    String uProfile;

    UserResgisterPostReq({
        required this.uName,
        required this.uEmail,
        required this.uPassword,
        required this.uProfile,
    });

    factory UserResgisterPostReq.fromJson(Map<String, dynamic> json) => UserResgisterPostReq(
        uName: json["u_name"],
        uEmail: json["u_email"], // แมพกับ JSON
        uPassword: json["u_password"],
        uProfile: json["u_profile"],
    );

    Map<String, dynamic> toJson() => {
        "u_name": uName,
        "u_email": uEmail,
        "u_password": uPassword,
        "u_profile": uProfile,
    };
}