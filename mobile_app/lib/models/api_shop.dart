class ApiShop {
  final int id;
  final String name;
  final String description;
  final String category;
  final String? image;
  final bool isActive;
  final int vendorId;
  final String vendorName;

  ApiShop({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.image,
    required this.isActive,
    required this.vendorId,
    required this.vendorName,
  });

  factory ApiShop.fromJson(Map<String, dynamic> json) {
    return ApiShop(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      image: json['image'] as String?,
      isActive: json['is_active'] as bool? ?? false,
      vendorId: json['vendor'] as int? ?? 0,
      vendorName: json['vendor_name'] as String? ?? '',
    );
  }

  ApiShop copyWith({
    int? id,
    String? name,
    String? description,
    String? category,
    String? image,
    bool? isActive,
    int? vendorId,
    String? vendorName,
  }) {
    return ApiShop(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      image: image ?? this.image,
      isActive: isActive ?? this.isActive,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
    );
  }
}
