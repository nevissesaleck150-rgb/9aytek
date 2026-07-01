class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final String image;
  final int vendorId;
  final double rating;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.image,
    required this.vendorId,
    required this.rating,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: double.parse(json['price'].toString()),
      image: json['image'],
      vendorId: json['vendor_id'],
      rating: double.parse(json['rating'].toString()),
    );
  }
}
