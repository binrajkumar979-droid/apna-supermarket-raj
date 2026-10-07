enum UserRole {
  customer,
  owner,
  manager,
  deliveryBoy;

  static UserRole fromString(String? role) {
    switch (role?.toLowerCase()) {
      case 'owner':
        return UserRole.owner;
      case 'manager':
        return UserRole.manager;
      case 'delivery_boy':
      case 'deliveryboy':
        return UserRole.deliveryBoy;
      default:
        return UserRole.customer;
    }
  }

  String get value {
    switch (this) {
      case UserRole.owner:
        return 'owner';
      case UserRole.manager:
        return 'manager';
      case UserRole.deliveryBoy:
        return 'delivery_boy';
      case UserRole.customer:
        return 'customer';
    }
  }
}

class UserModel {
  final String uid;
  final String phone;
  final String? alternatePhone;
  final String name;
  final UserRole role;
  final bool isBlocked;
  final DateTime createdAt;
  
  // Village & Address metadata
  final String? defaultVillageId;
  final String? defaultVillageName;

  // Release 2 fields
  final double walletBalance;
  final bool khataApproved;
  final double khataCreditLimit;
  final double khataCurrentBalance;

  // Release 3 fields
  final String loyaltyTier;
  final int loyaltyPoints;
  final String? referralCode;

  UserModel({
    required this.uid,
    required this.phone,
    this.alternatePhone,
    required this.name,
    this.role = UserRole.customer,
    this.isBlocked = false,
    DateTime? createdAt,
    this.defaultVillageId,
    this.defaultVillageName,
    this.walletBalance = 0.0,
    this.khataApproved = false,
    this.khataCreditLimit = 0.0,
    this.khataCurrentBalance = 0.0,
    this.loyaltyTier = 'Bronze',
    this.loyaltyPoints = 0,
    this.referralCode,
  }) : createdAt = createdAt ?? DateTime.now();

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      phone: map['phone'] ?? '',
      alternatePhone: map['alternate_phone'],
      name: map['name'] ?? '',
      role: UserRole.fromString(map['role']),
      isBlocked: map['is_blocked'] ?? false,
      createdAt: map['created_at'] != null 
          ? (map['created_at'] as dynamic).toDate() 
          : DateTime.now(),
      defaultVillageId: map['default_village_id'],
      defaultVillageName: map['default_village_name'],
      walletBalance: (map['wallet_balance'] as num?)?.toDouble() ?? 0.0,
      khataApproved: map['khata_approved'] ?? false,
      khataCreditLimit: (map['khata_credit_limit'] as num?)?.toDouble() ?? 0.0,
      khataCurrentBalance: (map['khata_current_balance'] as num?)?.toDouble() ?? 0.0,
      loyaltyTier: map['loyalty_tier'] ?? 'Bronze',
      loyaltyPoints: (map['loyalty_points'] as num?)?.toInt() ?? 0,
      referralCode: map['referral_code'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phone': phone,
      'alternate_phone': alternatePhone,
      'name': name,
      'role': role.value,
      'is_blocked': isBlocked,
      'created_at': createdAt,
      'default_village_id': defaultVillageId,
      'default_village_name': defaultVillageName,
      'wallet_balance': walletBalance,
      'khata_approved': khataApproved,
      'khata_credit_limit': khataCreditLimit,
      'khata_current_balance': khataCurrentBalance,
      'loyalty_tier': loyaltyTier,
      'loyalty_points': loyaltyPoints,
      'referral_code': referralCode,
    };
  }
}
