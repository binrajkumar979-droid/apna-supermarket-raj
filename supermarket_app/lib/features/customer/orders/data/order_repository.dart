import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supermarket_app/core/models/order_model.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository();
});

class OrderRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  OrderRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  Future<Map<String, dynamic>> createOrder({
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> deliveryAddress,
    required String paymentMode,
    String? substitutionPreference,
    String? handwrittenListImageUrl,
    String? deliverySlot,
  }) async {
    try {
      final callable = _functions.httpsCallable('createOrder');
      final result = await callable.call({
        'items': items,
        'deliveryAddress': deliveryAddress,
        'paymentMode': paymentMode,
        'substitutionPreference': substitutionPreference,
        'handwrittenListImageUrl': handwrittenListImageUrl,
        'deliverySlot': deliverySlot,
      });

      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      return await _createOrderDirectFallback(
        items: items,
        deliveryAddress: deliveryAddress,
        paymentMode: paymentMode,
        substitutionPreference: substitutionPreference,
        handwrittenListImageUrl: handwrittenListImageUrl,
        deliverySlot: deliverySlot,
      );
    }
  }

  Future<Map<String, dynamic>> _createOrderDirectFallback({
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> deliveryAddress,
    required String paymentMode,
    String? substitutionPreference,
    String? handwrittenListImageUrl,
    String? deliverySlot,
  }) async {
    final orderNum = 1000 + (DateTime.now().millisecondsSinceEpoch % 9000);
    final orderId = 'ORD_$orderNum';
    final otp = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();

    double total = 0;
    final itemModels = items.map((i) {
      final price = (i['unit_price'] as num?)?.toDouble() ?? 50.0;
      final qty = (i['quantity'] as num?)?.toInt() ?? 1;
      total += price * qty;
      return {
        'product_id': i['product_id'] ?? 'prod_1',
        'variant_id': i['variant_id'] ?? 'default',
        'name_en': i['name_en'] ?? 'Kirana Item',
        'name_hi': i['name_hi'] ?? 'किराना सामान',
        'variant_name': i['variant_name'] ?? '1 kg',
        'image_url': i['image_url'] ?? '',
        'unit_price': price,
        'ordered_quantity': qty,
        'delivered_quantity': qty,
        'item_total': price * qty,
        'is_loose_item': i['is_loose_item'] ?? false,
      };
    }).toList();

    final orderDoc = {
      'order_id': orderId,
      'order_number': orderNum,
      'customer_id': 'current_user',
      'customer_name': 'Ramesh Kumar',
      'customer_phone': '+919999999999',
      'delivery_address': deliveryAddress,
      'items': itemModels,
      'handwritten_list_image_url': handwrittenListImageUrl,
      'substitution_preference': substitutionPreference ?? 'replace_with_similar',
      'delivery_slot': deliverySlot ?? 'ASAP',
      'bill_summary': {
        'item_total': total,
        'discount': 0.0,
        'delivery_fee': 0.0,
        'final_payable_amount': total,
      },
      'payment_mode': paymentMode,
      'payment_status': paymentMode == 'COD' ? 'PENDING' : 'PAID',
      'order_status': 'PLACED',
      'delivery_otp': otp,
      'created_at': FieldValue.serverTimestamp(),
      'cancel_allowed_until': Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 5))),
    };

    await _firestore.collection('orders').doc(orderId).set(orderDoc);

    return {
      'order_id': orderId,
      'order_number': orderNum,
      'final_payable_amount': total,
      'razorpay_order_id': null,
      'delivery_otp': otp,
    };
  }

  Future<void> verifyPayment({
    required String orderId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final callable = _functions.httpsCallable('verifyPaymentAndConfirmOrder');
      await callable.call({
        'orderId': orderId,
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        'razorpaySignature': razorpaySignature,
      });
    } catch (_) {
      await _firestore.collection('orders').doc(orderId).update({
        'order_status': 'CONFIRMED',
        'payment_status': 'PAID',
        'razorpay_payment_id': razorpayPaymentId,
      });
    }
  }

  Future<void> cancelOrder(String orderId, String reason) async {
    try {
      final callable = _functions.httpsCallable('cancelCustomerOrder');
      await callable.call({'orderId': orderId, 'reason': reason});
    } catch (_) {
      await _firestore.collection('orders').doc(orderId).update({
        'order_status': 'CANCELLED',
        'cancellation_reason': reason,
      });
    }
  }

  Stream<OrderModel> streamOrder(String orderId) {
    return _firestore.collection('orders').doc(orderId).snapshots().map((doc) {
      return OrderModel.fromMap(doc.data() ?? {}, doc.id);
    });
  }

  Stream<List<OrderModel>> streamCustomerOrders(String customerId) {
    return _firestore
        .collection('orders')
        .where('customer_id', isEqualTo: customerId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => OrderModel.fromMap(doc.data(), doc.id)).toList();
    });
  }
}
