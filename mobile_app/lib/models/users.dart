class User {
  final int id;
  final String username;
  final String role; // (customer, vendor, influencer, driver, admin)
  final String? token;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? address;
  final double? latitude;
  final double? longitude;
  final double walletBalance;
  final bool isApproved;
  final String? bankAccount;
  final String? profileImage;
  final String? nationalId;
  final String? drivingLicense;
  // vendor shop fields
  final String? storeName;
  final String? storeDescription;
  final String? storeType;
  final String? storeLogo;
  // driver fields
  final String? vehicleType;
  final String? vehiclePlate;
  final String? vehicleImage;
  // influencer fields
  final String? socialLinks;
  final String? specialty;
  final String? resume;

  User({
    required this.id,
    required this.username,
    required this.role,
    this.token,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.address,
    this.latitude,
    this.longitude,
    this.walletBalance = 0,
    this.isApproved = true,
    this.bankAccount,
    this.profileImage,
    this.nationalId,
    this.drivingLicense,
    this.storeName,
    this.storeDescription,
    this.storeType,
    this.storeLogo,
    this.vehicleType,
    this.vehiclePlate,
    this.vehicleImage,
    this.socialLinks,
    this.specialty,
    this.resume,
  });

  String get displayName {
    final parts = [firstName, lastName]
        .whereType<String>()
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isNotEmpty) return parts.join(' ');
    return username;
  }

  User copyWith({
    String? username,
    String? role,
    double? walletBalance,
    String? token,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? address,
    double? latitude,
    double? longitude,
    bool? isApproved,
    String? bankAccount,
    String? profileImage,
    String? nationalId,
    String? drivingLicense,
    String? storeName,
    String? storeDescription,
    String? storeType,
    String? storeLogo,
    String? vehicleType,
    String? vehiclePlate,
    String? vehicleImage,
    String? socialLinks,
    String? specialty,
    String? resume,
  }) {
    return User(
      id: id,
      username: username ?? this.username,
      role: role ?? this.role,
      token: token ?? this.token,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      walletBalance: walletBalance ?? this.walletBalance,
      isApproved: isApproved ?? this.isApproved,
      bankAccount: bankAccount ?? this.bankAccount,
      profileImage: profileImage ?? this.profileImage,
      nationalId: nationalId ?? this.nationalId,
      drivingLicense: drivingLicense ?? this.drivingLicense,
      storeName: storeName ?? this.storeName,
      storeDescription: storeDescription ?? this.storeDescription,
      storeType: storeType ?? this.storeType,
      storeLogo: storeLogo ?? this.storeLogo,
      vehicleType: vehicleType ?? this.vehicleType,
      vehiclePlate: vehiclePlate ?? this.vehiclePlate,
      vehicleImage: vehicleImage ?? this.vehicleImage,
      socialLinks: socialLinks ?? this.socialLinks,
      specialty: specialty ?? this.specialty,
      resume: resume ?? this.resume,
    );
  }

  factory User.fromJson(Map<String, dynamic> json, String? token) {
    final wallet = json['wallet_balance'];
    final lat = json['latitude'];
    final lng = json['longitude'];
    return User(
      id: json['id'] as int,
      username: json['username'] as String? ?? '',
      role: json['role'] as String? ?? 'customer',
      token: token,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      latitude: lat == null ? null : double.tryParse(lat.toString()),
      longitude: lng == null ? null : double.tryParse(lng.toString()),
      walletBalance: wallet == null
          ? 0
          : double.tryParse(wallet.toString()) ?? 0,
      isApproved: json['is_approved'] == true,
      bankAccount: json['bank_account'] as String?,
      profileImage: json['profile_image'] as String?,
      nationalId: json['national_id'] as String?,
      drivingLicense: json['driving_license'] as String?,
      storeName: json['store_name'] as String?,
      storeDescription: json['store_description'] as String?,
      storeType: json['store_type'] as String?,
      storeLogo: json['store_logo'] as String?,
      vehicleType: json['vehicle_type'] as String?,
      vehiclePlate: json['vehicle_plate'] as String?,
      vehicleImage: json['vehicle_image'] as String?,
      socialLinks: json['social_links'] as String?,
      specialty: json['specialty'] as String?,
      resume: json['resume'] as String?,
    );
  }
}
