import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supermarket_app/core/models/product_model.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

class ProductRepository {
  final FirebaseFirestore _firestore;

  ProductRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<CategoryModel>> streamCategories() {
    return _firestore
        .collection('categories')
        .where('is_active', isEqualTo: true)
        .orderBy('display_order')
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return _getInitialMockCategories();
      }
      return snapshot.docs
          .map((doc) => CategoryModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<List<ProductModel>> streamTrendingProducts() {
    return _firestore
        .collection('products')
        .where('is_trending', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return _getInitialMockProducts();
      }
      return snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<List<ProductModel>> streamProductsByCategory(String categoryId) {
    return _firestore
        .collection('products')
        .where('category_id', isEqualTo: categoryId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return _getInitialMockProducts()
            .where((p) => p.categoryId == categoryId)
            .toList();
      }
      return snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  List<ProductModel> searchProducts(String query, List<ProductModel> allProducts) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return allProducts;

    return allProducts.where((product) {
      final matchEn = product.nameEn.toLowerCase().contains(cleanQuery);
      final matchHi = product.nameHi.toLowerCase().contains(cleanQuery);
      final matchKeywords = product.alternateSearchTerms.any(
        (term) => term.toLowerCase().contains(cleanQuery),
      );
      return matchEn || matchHi || matchKeywords;
    }).toList();
  }

  List<CategoryModel> _getInitialMockCategories() {
    return [
      CategoryModel(
        id: 'cat_staples',
        nameEn: 'Atta, Rice & Dal',
        nameHi: 'आटा, चावल और दाल',
        imageUrl: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=300&auto=format&fit=crop&q=80',
        displayOrder: 1,
      ),
      CategoryModel(
        id: 'cat_oil_masala',
        nameEn: 'Oil, Ghee & Masala',
        nameHi: 'तेल, घी और मसाले',
        imageUrl: 'https://images.unsplash.com/photo-1596040033229-a9821ebd058d?w=300&auto=format&fit=crop&q=80',
        displayOrder: 2,
      ),
      CategoryModel(
        id: 'cat_dairy',
        nameEn: 'Dairy & Bakery',
        nameHi: 'दूध, दही और ब्रेड',
        imageUrl: 'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=300&auto=format&fit=crop&q=80',
        displayOrder: 3,
      ),
      CategoryModel(
        id: 'cat_snacks',
        nameEn: 'Snacks & Biscuits',
        nameHi: 'नमकीन और बिस्कुट',
        imageUrl: 'https://images.unsplash.com/photo-1599490659213-e2b9527bd087?w=300&auto=format&fit=crop&q=80',
        displayOrder: 4,
      ),
      CategoryModel(
        id: 'cat_cleaning',
        nameEn: 'Soaps & Detergents',
        nameHi: 'साबुन और डिटर्जेंट',
        imageUrl: 'https://images.unsplash.com/photo-1583947215259-38e31be8751f?w=300&auto=format&fit=crop&q=80',
        displayOrder: 5,
      ),
    ];
  }

  List<ProductModel> _getInitialMockProducts() {
    return [
      ProductModel(
        id: 'prod_aashirvaad_atta',
        barcode: '8901030383792',
        categoryId: 'cat_staples',
        nameEn: 'Aashirvaad Shudh Chakki Atta',
        nameHi: 'आशीर्वाद शुद्ध चक्की आटा',
        alternateSearchTerms: ['atta', 'aata', 'wheat flour', 'gehu ka aata'],
        images: ['https://images.unsplash.com/photo-1509440159596-0249088772ff?w=600&auto=format&fit=crop&q=80'],
        descriptionEn: '100% pure whole wheat flour processed with superior chakki grinding.',
        descriptionHi: '100% शुद्ध साबुत गेहूं का आटा।',
        mrp: 260.0,
        sellingPrice: 235.0,
        unitType: 'kg',
        variants: [
          ProductVariant(variantId: 'v_5kg', variantName: '5 kg', mrp: 260.0, sellingPrice: 235.0, stockQuantity: 30),
          ProductVariant(variantId: 'v_10kg', variantName: '10 kg', mrp: 510.0, sellingPrice: 455.0, stockQuantity: 15),
        ],
        stockQuantity: 45,
        isTrending: true,
      ),
      ProductModel(
        id: 'prod_loose_sugar',
        barcode: '',
        categoryId: 'cat_staples',
        nameEn: 'Pure White Sugar (Loose Kirana)',
        nameHi: 'सफेद चीनी (खुली)',
        alternateSearchTerms: ['chini', 'sugar', 'shakkar', 'khuli chini'],
        images: ['https://images.unsplash.com/photo-1581441363689-1f3c3c414635?w=600&auto=format&fit=crop&q=80'],
        descriptionEn: 'Clean, sweet crystal sugar weighed fresh from Kirana sack.',
        descriptionHi: 'साफ सुथरी खुली दानेदार चीनी (वजन तोलकर दिया जाएगा)।',
        isLooseItem: true,
        mrp: 48.0,
        sellingPrice: 42.0,
        unitType: 'kg',
        variants: [
          ProductVariant(variantId: 'v_1kg', variantName: '1 kg', mrp: 48.0, sellingPrice: 42.0, stockQuantity: 100),
          ProductVariant(variantId: 'v_5kg', variantName: '5 kg', mrp: 240.0, sellingPrice: 205.0, stockQuantity: 20),
        ],
        stockQuantity: 120,
        isTrending: true,
      ),
      ProductModel(
        id: 'prod_fortune_oil',
        barcode: '8906007280014',
        categoryId: 'cat_oil_masala',
        nameEn: 'Fortune Sunlite Refined Sunflower Oil',
        nameHi: 'फॉर्च्यून रिफाइंड सूरजमुखी तेल',
        alternateSearchTerms: ['oil', 'tel', 'refined tel', 'sunflower oil'],
        images: ['https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=600&auto=format&fit=crop&q=80'],
        descriptionEn: 'Light, healthy cooking sunflower oil pouch.',
        descriptionHi: 'हल्का और सेहतमंद रिफाइंड तेल।',
        mrp: 165.0,
        sellingPrice: 142.0,
        unitType: 'litre',
        variants: [
          ProductVariant(variantId: 'v_1l', variantName: '1 Litre Pouch', mrp: 165.0, sellingPrice: 142.0, stockQuantity: 50),
        ],
        stockQuantity: 50,
        isTrending: true,
      ),
      ProductModel(
        id: 'prod_tata_salt',
        barcode: '8901030383000',
        categoryId: 'cat_oil_masala',
        nameEn: 'Tata Salt Vacuum Evaporated Iodized',
        nameHi: 'टाटा नमक (देश का नमक)',
        alternateSearchTerms: ['namak', 'salt', 'tata namak'],
        images: ['https://images.unsplash.com/photo-1518110925495-5fe2fda0442c?w=600&auto=format&fit=crop&q=80'],
        descriptionEn: 'India’s trusted vacuum evaporated iodised salt.',
        descriptionHi: 'शुद्ध आयोडीन युक्त टाटा नमक।',
        mrp: 28.0,
        sellingPrice: 25.0,
        unitType: 'kg',
        variants: [
          ProductVariant(variantId: 'v_1kg', variantName: '1 kg', mrp: 28.0, sellingPrice: 25.0, stockQuantity: 80),
        ],
        stockQuantity: 80,
        isTrending: true,
      ),
    ];
  }
}
