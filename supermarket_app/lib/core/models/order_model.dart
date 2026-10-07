import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  placed,
  confirmed,
  packed,
  outForDelivery,
  delivered,
  cancelled;

  static OrderStatus fromString(String? status) {
    switch (status?.toUpperCase()) {
      case 'CONFIRMED':
        return OrderStatus.confirmed;
      case 'PACKED':
        return OrderStatus.packed;
      case 'OUT_FOR_DELIVERY':
        return OrderStatus.outForDelivery;
      case 'DELIVERED':
        return OrderStatus.delivered;
      case 'CANCELLED':
        return OrderStatus.cancelled;
      case 'PLACED':
      default:
        return OrderStatus.placed;
    }
  }

  String get labelEn {
    switch (this) {
      case OrderStatus.placed:
        return 'Order Placed';
      case OrderStatus.confirmed:
        return 'Confirmed by Store';
      case OrderStatus.packed:
        return 'Items Packed';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get labelHi {
    switch (this) {
      case OrderStatus.placed:
        return 'ऑर्डर दर्ज हुआ';
      case OrderStatus.confirmed:
        return 'दुकानदार ने स्वीकार किया';
      case OrderStatus.packed:
        return 'सामान पैक हो गया';
      case OrderStatus.outForDelivery:
        return 'डिलीवरी के लिए निकल गया';
      case OrderStatus.delivered:
        return 'डिलीवर हो गया';
      case OrderStatus.cancelled:
        return 'ऑर्डर रद्द हुआ';
    }
  }
}

class OrderItemModel {
  final String productId;
  final String variantId;
  final String nameEn;
  final String nameHi;
  final String variantName;
  final String imageUrl;
  final double unitPrice;
  final int orderedQuantity;
  final int deliveredQuantity;
  final String? actualWeight;
  final double itemTotal;
  final bool isLooseItem;

  OrderItemModel({
    required this.productId,
    required this.variantId,
    required this.nameEn,
    required this.nameHi,
    required this.variantName,
    required this.imageUrl,
    required this.unitPrice,
    required this.orderedQuantity,
    required this.deliveredQuantity,
    this.actualWeight,
    required this.itemTotal,
    this.isLooseItem = false,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      productId: map['product_id'] ?? '',
      variantId: map['variant_id'] ?? 'default',
      nameEn: map['name_en'] ?? '',
      nameHi: map['name_hi'] ?? '',
      variantName: map['variant_name'] ?? '',
      imageUrl: map['image_url'] ?? '',
      unitPrice: (map['unit_price'] as num?)?.toDouble() ?? 0.0,
      orderedQuantity: (map['ordered_quantity'] as num?)?.toInt() ?? 1,
      deliveredQuantity: (map['delivered_quantity'] as num?)?.toInt() ?? 1,
      actualWeight: map['actual_weight'],
      itemTotal: (map['item_total'] as num?)?.toDouble() ?? 0.0,
      isLooseItem: map['is_loose_item'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'product_id': productId,
      'variant_id': variantId,
      'name_en': nameEn,
      'name_hi': nameHi,
      'variant_name': variantName,
      'image_url': imageUrl,
      'unit_price': unitPrice,
      'ordered_quantity': orderedQuantity,
      'delivered_quantity': deliveredQuantity,
      'actual_weight': actualWeight,
      'item_total': itemTotal,
      'is_loose_item': isLooseItem,
    };
  }
}

class OrderModel {
  final String orderId;
  final int orderNumber;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final Map<String, dynamic> deliveryAddress;
  final List<OrderItemModel> items;
  final String? handwrittenListImageUrl;
  final String substitutionPreference;
  final String deliverySlot;
  final double itemTotal;
  final double discount;
  final double deliveryFee;
  final double finalPayableAmount;
  final String paymentMode; // "COD" | "ONLINE_RAZORPAY" | "KHATA"
  final String paymentStatus; // "PENDING" | "PAID" | "REFUNDED"
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final OrderStatus orderStatus;
  final String deliveryOtp;
  final String? assignedDeliveryBoyId;
  final String? assignedDeliveryBoyName;
  final String? assignedDeliveryBoyPhone;
  final String? cancellationReason;
  final DateTime createdAt;
  final DateTime cancelAllowedUntil;

  OrderModel({
    required this.orderId,
    required this.orderNumber,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.items,
    this.handwrittenListImageUrl,
    this.substitutionPreference = 'replace_with_similar',
    this.deliverySlot = 'ASAP',
    required this.itemTotal,
    this.discount = 0.0,
    this.deliveryFee = 0.0,
    required this.finalPayableAmount,
    this.paymentMode = 'COD',
    this.paymentStatus = 'PENDING',
    this.razorpayOrderId,
    this.razorpayPaymentId,
    this.orderStatus = OrderStatus.placed,
    required this.deliveryOtp,
    this.assignedDeliveryBoyId,
    this.assignedDeliveryBoyName,
    this.assignedDeliveryBoyPhone,
    this.cancellationReason,
    DateTime? createdAt,
    DateTime? cancelAllowedUntil,
  })  : createdAt = createdAt ?? DateTime.now(),
        cancelAllowedUntil = cancelAllowedUntil ?? DateTime.now().add(const Duration(minutes: 5));

  factory OrderModel.fromMap(Map<String, dynamic> map, String id) {
    final bill = (map['bill_summary'] as Map<String, dynamic>?) ?? {};
    return OrderModel(
      orderId: map['order_id'] ?? id,
      orderNumber: (map['order_number'] as num?)?.toInt() ?? 1000,
      customerId: map['customer_id'] ?? '',
      customerName: map['customer_name'] ?? 'Customer',
      customerPhone: map['customer_phone'] ?? '',
      deliveryAddress: Map<String, dynamic>.from(map['delivery_address'] ?? {}),
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => OrderItemModel.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      handwrittenListImageUrl: map['handwritten_list_image_url'],
      substitutionPreference: map['substitution_preference'] ?? 'replace_with_similar',
      deliverySlot: map['delivery_slot'] ?? 'ASAP',
      itemTotal: (bill['item_total'] as num?)?.toDouble() ?? 0.0,
      discount: (bill['discount'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (bill['delivery_fee'] as num?)?.toDouble() ?? 0.0,
      finalPayableAmount: (bill['final_payable_amount'] as num?)?.toDouble() ?? 0.0,
      paymentMode: map['payment_mode'] ?? 'COD',
      paymentStatus: map['payment_status'] ?? 'PENDING',
      razorpayOrderId: map['razorpay_order_id'],
      razorpayPaymentId: map['razorpay_payment_id'],
      orderStatus: OrderStatus.fromString(map['order_status']),
      deliveryOtp: map['delivery_otp'] ?? '0000',
      assignedDeliveryBoyId: map['assigned_delivery_boy_id'],
      assignedDeliveryBoyName: map['assigned_delivery_boy_name'],
      assignedDeliveryBoyPhone: map['assigned_delivery_boy_phone'],
      cancellationReason: map['cancellation_reason'],
      createdAt: map['created_at'] != null ? (map['created_at'] as Timestamp).toDate() : DateTime.now(),
      cancelAllowedUntil: map['cancel_allowed_until'] != null
          ? (map['cancel_allowed_until'] as Timestamp).toDate()
          : DateTime.now().add(const Duration(minutes: 5)),
    );
  }

  bool get canBeCancelled =>
      DateTime.now().isBefore(cancelAllowedUntil) &&
      orderStatus != OrderStatus.delivered &&
      orderStatus != OrderStatus.cancelled;

  int get remainingCancelSeconds {
    final diff = cancelAllowedUntil.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }
}
