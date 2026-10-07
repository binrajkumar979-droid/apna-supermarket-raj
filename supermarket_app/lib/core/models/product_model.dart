class ProductVariant {
  final String variantId;
  final String variantName;
  final double mrp;
  final double sellingPrice;
  final int stockQuantity;

  ProductVariant({
    required this.variantId,
    required this.variantName,
    required this.mrp,
    required this.sellingPrice,
    required this.stockQuantity,
  });

  factory ProductVariant.fromMap(Map<String, dynamic> map) {
    return ProductVariant(
      variantId: map['variant_id'] ?? '',
      variantName: map['variant_name'] ?? '',
      mrp: (map['mrp'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (map['selling_price'] as num?)?.toDouble() ?? 0.0,
      stockQuantity: (map['stock_quantity'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'variant_id': variantId,
      'variant_name': variantName,
      'mrp': mrp,
      'selling_price': sellingPrice,
      'stock_quantity': stockQuantity,
    };
  }

  double get discountPercent {
    if (mrp <= sellingPrice || mrp == 0) return 0;
    return (((mrp - sellingPrice) / mrp) * 100);
  }
}

class ProductModel {
  final String id;
  final String barcode;
  final String categoryId;
  final String nameEn;
  final String nameHi;
  final List<String> alternateSearchTerms;
  final List<String> images;
  final String descriptionEn;
  final String descriptionHi;
  final bool isLooseItem; // e.g. Chini, daal, aloo (weight verified on packing)
  final double costPrice;
  final double mrp;
  final double sellingPrice;
  final String unitType; // kg, g, litre, ml, packet, piece
  final List<ProductVariant> variants;
  final int stockQuantity;
  final bool isInStock;
  final int lowStockThreshold;
  final String? expiryDate;
  final bool isTrending;

  ProductModel({
    required this.id,
    this.barcode = '',
    required this.categoryId,
    required this.nameEn,
    required this.nameHi,
    this.alternateSearchTerms = const [],
    this.images = const [],
    this.descriptionEn = '',
    this.descriptionHi = '',
    this.isLooseItem = false,
    this.costPrice = 0.0,
    required this.mrp,
    required this.sellingPrice,
    this.unitType = 'piece',
    this.variants = const [],
    this.stockQuantity = 10,
    this.isInStock = true,
    this.lowStockThreshold = 5,
    this.expiryDate,
    this.isTrending = false,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map, String id) {
    return ProductModel(
      id: id,
      barcode: map['barcode'] ?? '',
      categoryId: map['category_id'] ?? '',
      nameEn: map['name_en'] ?? '',
      nameHi: map['name_hi'] ?? '',
      alternateSearchTerms: List<String>.from(map['alternate_search_terms'] ?? []),
      images: List<String>.from(map['images'] ?? []),
      descriptionEn: map['description_en'] ?? '',
      descriptionHi: map['description_hi'] ?? '',
      isLooseItem: map['is_loose_item'] ?? false,
      costPrice: (map['cost_price'] as num?)?.toDouble() ?? 0.0,
      mrp: (map['mrp'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (map['selling_price'] as num?)?.toDouble() ?? 0.0,
      unitType: map['unit_type'] ?? 'piece',
      variants: (map['variants'] as List<dynamic>?)
              ?.map((v) => ProductVariant.fromMap(v as Map<String, dynamic>))
              .toList() ??
          [],
      stockQuantity: (map['stock_quantity'] as num?)?.toInt() ?? 0,
      isInStock: map['is_in_stock'] ?? true,
      lowStockThreshold: (map['low_stock_threshold'] as num?)?.toInt() ?? 5,
      expiryDate: map['expiry_date'],
      isTrending: map['is_trending'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'barcode': barcode,
      'category_id': categoryId,
      'name_en': nameEn,
      'name_hi': nameHi,
      'alternate_search_terms': alternateSearchTerms,
      'images': images,
      'description_en': descriptionEn,
      'description_hi': descriptionHi,
      'is_loose_item': isLooseItem,
      'cost_price': costPrice,
      'mrp': mrp,
      'selling_price': sellingPrice,
      'unit_type': unitType,
      'variants': variants.map((v) => v.toMap()).toList(),
      'stock_quantity': stockQuantity,
      'is_in_stock': isInStock,
      'low_stock_threshold': lowStockThreshold,
      'expiry_date': expiryDate,
      'is_trending': isTrending,
    };
  }

  double get discountPercent {
    if (mrp <= sellingPrice || mrp == 0) return 0;
    return (((mrp - sellingPrice) / mrp) * 100);
  }

  String get primaryImage {
    if (images.isNotEmpty) return images.first;
    return 'https://images.unsplash.com/photo-1542838132-92c53300491e?w=500&auto=format&fit=crop&q=80';
  }
}

class CategoryModel {
  final String id;
  final String nameEn;
  final String nameHi;
  final String imageUrl;
  final int displayOrder;
  final bool isActive;

  CategoryModel({
    required this.id,
    required this.nameEn,
    required this.nameHi,
    required this.imageUrl,
    this.displayOrder = 1,
    this.isActive = true,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map, String id) {
    return CategoryModel(
      id: id,
      nameEn: map['name_en'] ?? '',
      nameHi: map['name_hi'] ?? '',
      imageUrl: map['image_url'] ?? '',
      displayOrder: (map['display_order'] as num?)?.toInt() ?? 1,
      isActive: map['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name_en': nameEn,
      'name_hi': nameHi,
      'image_url': imageUrl,
      'display_order': displayOrder,
      'is_active': isActive,
    };
  }
}
