class VillageModel {
  final String id;
  final String nameEn;
  final String nameHi;
  final String pincode;
  final String block;
  final String district;
  final bool isActive;
  final int estimatedDeliveryMins;

  VillageModel({
    required this.id,
    required this.nameEn,
    required this.nameHi,
    required this.pincode,
    required this.block,
    required this.district,
    this.isActive = true,
    this.estimatedDeliveryMins = 45,
  });

  factory VillageModel.fromMap(Map<String, dynamic> map, String id) {
    return VillageModel(
      id: id,
      nameEn: map['village_name_en'] ?? '',
      nameHi: map['village_name_hi'] ?? '',
      pincode: map['pincode'] ?? '',
      block: map['block'] ?? '',
      district: map['district'] ?? '',
      isActive: map['is_active'] ?? true,
      estimatedDeliveryMins: map['estimated_delivery_mins'] ?? 45,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'village_name_en': nameEn,
      'village_name_hi': nameHi,
      'pincode': pincode,
      'block': block,
      'district': district,
      'is_active': isActive,
      'estimated_delivery_mins': estimatedDeliveryMins,
    };
  }
}

class AddressModel {
  final String id;
  final String userId;
  final bool isDefault;
  final String houseNo;
  final String villageId;
  final String villageName;
  final String areaMohalla;
  final String landmark;
  final String postOffice;
  final String block;
  final String district;
  final String pincode;
  final double? latitude;
  final double? longitude;

  AddressModel({
    required this.id,
    required this.userId,
    this.isDefault = false,
    required this.houseNo,
    required this.villageId,
    required this.villageName,
    required this.areaMohalla,
    required this.landmark,
    required this.postOffice,
    required this.block,
    required this.district,
    required this.pincode,
    this.latitude,
    this.longitude,
  });

  factory AddressModel.fromMap(Map<String, dynamic> map, String id) {
    return AddressModel(
      id: id,
      userId: map['user_id'] ?? '',
      isDefault: map['is_default'] ?? false,
      houseNo: map['house_no'] ?? '',
      villageId: map['village_id'] ?? '',
      villageName: map['village_name'] ?? '',
      areaMohalla: map['area_mohalla'] ?? '',
      landmark: map['landmark'] ?? '',
      postOffice: map['post_office'] ?? '',
      block: map['block'] ?? '',
      district: map['district'] ?? '',
      pincode: map['pincode'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'is_default': isDefault,
      'house_no': houseNo,
      'village_id': villageId,
      'village_name': villageName,
      'area_mohalla': areaMohalla,
      'landmark': landmark,
      'post_office': postOffice,
      'block': block,
      'district': district,
      'pincode': pincode,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  String get fullAddressFormatted {
    return "$houseNo, $areaMohalla, Gaon: $villageName, Landmark: $landmark, $pincode";
  }
}
