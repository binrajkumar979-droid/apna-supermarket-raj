import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supermarket_app/config/app_config.dart';
import 'package:supermarket_app/core/models/product_model.dart';

class CartItem {
  final ProductModel product;
  final ProductVariant variant;
  final int quantity;

  CartItem({
    required this.product,
    required this.variant,
    this.quantity = 1,
  });

  double get totalPrice => variant.sellingPrice * quantity;
  double get totalMrp => variant.mrp * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      product: product,
      variant: variant,
      quantity: quantity ?? this.quantity,
    );
  }
}

class CartState {
  final Map<String, CartItem> items;
  final String substitutionPreference;
  final String? handwrittenListImageUrl;

  CartState({
    this.items = const {},
    this.substitutionPreference = 'replace_with_similar',
    this.handwrittenListImageUrl,
  });

  int get totalItemCount => items.values.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => items.values.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get totalMrp => items.values.fold(0.0, (sum, item) => sum + item.totalMrp);
  double get totalSavings => totalMrp > subtotal ? totalMrp - subtotal : 0.0;
  
  double get deliveryFee => AppConfig.defaultDeliveryFee;
  double get finalTotal => subtotal + deliveryFee;

  bool get meetsMinOrder => subtotal >= AppConfig.defaultMinOrderValue;
  double get amountNeededForMinOrder =>
      meetsMinOrder ? 0.0 : (AppConfig.defaultMinOrderValue - subtotal);

  bool get hasLooseItems => items.values.any((i) => i.product.isLooseItem);

  CartState copyWith({
    Map<String, CartItem>? items,
    String? substitutionPreference,
    String? handwrittenListImageUrl,
  }) {
    return CartState(
      items: items ?? this.items,
      substitutionPreference: substitutionPreference ?? this.substitutionPreference,
      handwrittenListImageUrl: handwrittenListImageUrl ?? this.handwrittenListImageUrl,
    );
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState());

  void addItem(ProductModel product, ProductVariant variant) {
    final key = '${product.id}_${variant.variantId}';
    final currentMap = Map<String, CartItem>.from(state.items);

    if (currentMap.containsKey(key)) {
      currentMap[key] = currentMap[key]!.copyWith(
        quantity: currentMap[key]!.quantity + 1,
      );
    } else {
      currentMap[key] = CartItem(product: product, variant: variant, quantity: 1);
    }

    state = state.copyWith(items: currentMap);
  }

  void removeOrDecrement(ProductModel product, ProductVariant variant) {
    final key = '${product.id}_${variant.variantId}';
    final currentMap = Map<String, CartItem>.from(state.items);

    if (!currentMap.containsKey(key)) return;

    if (currentMap[key]!.quantity > 1) {
      currentMap[key] = currentMap[key]!.copyWith(
        quantity: currentMap[key]!.quantity - 1,
      );
    } else {
      currentMap.remove(key);
    }

    state = state.copyWith(items: currentMap);
  }

  void removeItem(String key) {
    final currentMap = Map<String, CartItem>.from(state.items);
    currentMap.remove(key);
    state = state.copyWith(items: currentMap);
  }

  void setSubstitutionPreference(String preference) {
    state = state.copyWith(substitutionPreference: preference);
  }

  void setHandwrittenListImage(String? url) {
    state = state.copyWith(handwrittenListImageUrl: url);
  }

  void clearCart() {
    state = CartState();
  }
}
