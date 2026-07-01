class InfluencerAd {
  final int id;
  final int influencerId;
  final String influencerName;
  final String influencerPhone;
  final String description;
  final int priceMru;
  final String imageUrl;
  final bool isActive;
  final DateTime createdAt;

  InfluencerAd({
    required this.id,
    required this.influencerId,
    required this.influencerName,
    required this.influencerPhone,
    required this.description,
    required this.priceMru,
    required this.imageUrl,
    required this.isActive,
    required this.createdAt,
  });

  factory InfluencerAd.fromJson(Map<String, dynamic> json) {
    return InfluencerAd(
      id: json['id'] ?? 0,
      influencerId: json['influencer_id'] ?? 0,
      influencerName: json['influencer_name'] ?? '',
      influencerPhone: json['influencer_phone'] ?? '',
      description: json['description'] ?? '',
      priceMru: json['price_mru'] ?? 0,
      imageUrl: json['image_url'] ?? '',
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'influencer_id': influencerId,
    'influencer_name': influencerName,
    'influencer_phone': influencerPhone,
    'description': description,
    'price_mru': priceMru,
    'image_url': imageUrl,
    'is_active': isActive,
    'created_at': createdAt.toIso8601String(),
  };
}
