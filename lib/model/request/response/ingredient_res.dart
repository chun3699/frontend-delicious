// To parse this JSON data, do
//
//     final ingredientRes = ingredientResFromJson(jsonString);

import 'dart:convert';

IngredientRes ingredientResFromJson(String str) => IngredientRes.fromJson(json.decode(str));

String ingredientResToJson(IngredientRes data) => json.encode(data.toJson());

class IngredientRes {
    int ingId;
    String ingName;
    String ingDetail;
    String ingImage;
    int ingTypeId;
    String ingTypeName;

    IngredientRes({
        required this.ingId,
        required this.ingName,
        required this.ingDetail,
        required this.ingImage,
        required this.ingTypeId,
        required this.ingTypeName,
    });

    factory IngredientRes.fromJson(Map<String, dynamic> json) => IngredientRes(
        ingId: json["ing_id"],
        ingName: json["ing_name"],
        ingDetail: json["ing_detail"],
        ingImage: json["ing_image"],
        ingTypeId: json["ing_type_id"],
        ingTypeName: json["ing_type_name"],
    );

    Map<String, dynamic> toJson() => {
        "ing_id": ingId,
        "ing_name": ingName,
        "ing_detail": ingDetail,
        "ing_image": ingImage,
        "ing_type_id": ingTypeId,
        "ing_type_name": ingTypeName,
    };
}
