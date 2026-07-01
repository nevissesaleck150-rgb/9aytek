import '../config/api_config.dart';

class ApiProduct {
  final int id;
  final String name;
  final String description;
  final int priceMru;
  final String? imagePath;
  final int vendorId;
  final String vendorName;
  final int stockQuantity;

  ApiProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.priceMru,
    this.imagePath,
    required this.vendorId,
    required this.vendorName,
    this.stockQuantity = 0,
  });

  String? get imageUrl => ApiConfig.mediaUrl(imagePath);

  factory ApiProduct.fromJson(Map<String, dynamic> json) {
    return ApiProduct(
      id: _toInt(json['id']),
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      priceMru: _toInt(json['price']),
      imagePath: json['image'] as String?,
      vendorId: _toInt(json['vendor']),
      vendorName: json['vendor_name'] as String? ?? '',
      stockQuantity: _toInt(json['stock_quantity']),
    );
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return double.tryParse(v.toString())?.round() ?? 0;
  }
}
