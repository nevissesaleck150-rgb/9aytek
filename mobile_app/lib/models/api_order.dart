class ApiOrderItem {
  final int id;
  final String itemName;
  final String itemDescription;
  final String? itemType;
  final String? contentLink;
  final int quantity;
  final int? vendorId;
  final bool vendorReady;
  final String? topupAccountId;
  final String? topupPayer;
  final String? topupRechargeType;
  final int? digitalServiceId;
  final int? productId;

  ApiOrderItem({
    required this.id,
    required this.itemName,
    this.itemDescription = '',
    this.itemType,
    this.contentLink,
    required this.quantity,
    this.vendorId,
    this.vendorReady = false,
    this.topupAccountId,
    this.topupPayer,
    this.topupRechargeType,
    this.digitalServiceId,
    this.productId,
  });

  factory ApiOrderItem.fromJson(Map<String, dynamic> json) {
    return ApiOrderItem(
      id: json['id'] as int,
      itemName: json['item_name'] as String? ?? '',
      itemDescription: json['item_description'] as String? ?? '',
      itemType: json['item_type'] as String?,
      contentLink: json['content_link'] as String?,
      quantity: json['quantity'] as int? ?? 1,
      vendorId: json['vendor_id'] as int?,
      vendorReady: json['vendor_ready'] as bool? ?? false,
      topupAccountId: json['topup_account_id'] as String?,
      topupPayer: json['topup_payer'] as String?,
      topupRechargeType: json['topup_recharge_type'] as String?,
      digitalServiceId: json['digital_service_id'] as int?,
      productId: json['product_id'] as int?,
    );
  }
}

class VendorLocation {
  final int vendorId;
  final String name;
  final double? lat;
  final double? lng;

  VendorLocation({
    required this.vendorId,
    required this.name,
    this.lat,
    this.lng,
  });

  factory VendorLocation.fromJson(Map<String, dynamic> json) {
    return VendorLocation(
      vendorId: json['vendor_id'] as int,
      name: json['name'] as String? ?? '',
      lat: _toLatLng(json['lat']),
      lng: _toLatLng(json['lng']),
    );
  }
}

class DriverInfo {
  final String fullName;
  final String? email;
  final String? phone;
  final String? profileImage;
  final String? vehicleType;
  final String? vehiclePlate;
  final String? vehicleImage;

  DriverInfo({
    required this.fullName,
    this.email,
    this.phone,
    this.profileImage,
    this.vehicleType,
    this.vehiclePlate,
    this.vehicleImage,
  });

  factory DriverInfo.fromJson(Map<String, dynamic> json) {
    return DriverInfo(
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      profileImage: json['profile_image'] as String?,
      vehicleType: json['vehicle_type'] as String?,
      vehiclePlate: json['vehicle_plate'] as String?,
      vehicleImage: json['vehicle_image'] as String?,
    );
  }
}

class ApiOrder {
  final int id;
  final String? customerName;
  final int? driverId;
  final String? driverName;
  final int totalMru;
  final String status;
  final DateTime? createdAt;
  final List<ApiOrderItem> items;
  final int? driverRating;
  final bool isSharesDistributed;
  final double? vendorLat;
  final double? vendorLng;
  final double? customerLat;
  final double? customerLng;
  final String? deliveryAddress;
  final int vendorsReady;
  final int vendorsTotal;
  final bool allVendorsReady;
  final List<VendorLocation> vendorLocations;
  final double influencerEarnings;
  final DriverInfo? driverInfo;

  ApiOrder({
    required this.id,
    this.customerName,
    this.driverId,
    this.driverName,
    required this.totalMru,
    required this.status,
    this.createdAt,
    this.items = const [],
    this.driverRating,
    this.isSharesDistributed = false,
    this.vendorLat,
    this.vendorLng,
    this.customerLat,
    this.customerLng,
    this.deliveryAddress,
    this.vendorsReady = 0,
    this.vendorsTotal = 0,
    this.allVendorsReady = true,
    this.vendorLocations = const [],
    this.influencerEarnings = 0.0,
    this.driverInfo,
  });

  String get displayId => '#$id';

  factory ApiOrder.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'];
    final vr = json['vendors_ready'];
    return ApiOrder(
      id: json['id'] as int,
      customerName: json['customer_name'] as String?,
      driverId: json['driver'] as int?,
      driverName: json['driver_name'] as String?,
      totalMru: _amount(json['total_amount']),
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      items: itemsJson is List
          ? itemsJson
                .map((e) => ApiOrderItem.fromJson(e as Map<String, dynamic>))
                .toList()
          : [],
      driverRating: json['driver_rating'] as int?,
      isSharesDistributed: json['is_shares_distributed'] as bool? ?? false,
      vendorLat: _toLatLng(json['vendor_latitude']),
      vendorLng: _toLatLng(json['vendor_longitude']),
      customerLat: _toLatLng(json['customer_latitude']),
      customerLng: _toLatLng(json['customer_longitude']),
      deliveryAddress: json['delivery_address'] as String?,
      vendorsReady: vr is Map ? (vr['ready'] as int? ?? 0) : 0,
      vendorsTotal: vr is Map ? (vr['total'] as int? ?? 0) : 0,
      allVendorsReady: vr is Map ? (vr['all_ready'] as bool? ?? true) : true,
      vendorLocations: json['vendor_locations'] is List
          ? (json['vendor_locations'] as List)
                .map((e) => VendorLocation.fromJson(e as Map<String, dynamic>))
                .toList()
          : [],
      influencerEarnings:
          double.tryParse((json['influencer_earnings'] ?? 0).toString()) ?? 0.0,
      driverInfo: json['driver_info'] is Map<String, dynamic>
          ? DriverInfo.fromJson(json['driver_info'] as Map<String, dynamic>)
          : null,
    );
  }
}

int _amount(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  return double.tryParse(v.toString())?.round() ?? 0;
}

double? _toLatLng(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString());
}
