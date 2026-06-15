import 'dart:convert';

AdminAddUserPostReq adminAddUserPostReqFromJson(String str) => AdminAddUserPostReq.fromJson(json.decode(str));

String adminAddUserPostReqToJson(AdminAddUserPostReq data) => json.encode(data.toJson());

class AdminAddUserPostReq {
    String uName;
    String uEmail;
    String uPassword;
    String uRole;
    String uProfile;

    AdminAddUserPostReq({
        required this.uName,
        required this.uEmail,
        required this.uPassword,
        required this.uRole,
        required this.uProfile,
    });

    factory AdminAddUserPostReq.fromJson(Map<String, dynamic> json) => AdminAddUserPostReq(
        uName: json["u_name"],
        uEmail: json["u_email"],
        uPassword: json["u_password"],
        uRole: json["u_role"],
        uProfile: json["u_profile"],
    );

    Map<String, dynamic> toJson() => {
        "u_name": uName,
        "u_email": uEmail,
        "u_password": uPassword,
        "u_role": uRole,
        "u_profile": uProfile,
    };
}
