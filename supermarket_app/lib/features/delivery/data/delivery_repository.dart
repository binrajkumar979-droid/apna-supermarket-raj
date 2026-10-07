import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supermarket_app/core/models/order_model.dart';

final deliveryRepositoryProvider = Provider<DeliveryRepository>((ref) {
  return DeliveryRepository();
});

class DeliveryRepository {
  final FirebaseFirestore _firestore;

  DeliveryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<OrderModel>> streamAssignedOrders(String deliveryBoyId) {
    return _firestore
        .collection('orders')
        .where('order_status', whereIn: ['OUT_FOR_DELIVERY', 'DELIVERED', 'PACKED'])
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => OrderModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<bool> verifyOtpAndCompleteDelivery({
    required String orderId,
    required String enteredOtp,
    required String actualOtp,
    required bool isCod,
  }) async {
    if (enteredOtp.trim() != actualOtp.trim()) {
      return false;
    }

    final updateData = <String, dynamic>{
      'order_status': 'DELIVERED',
      'delivered_at': FieldValue.serverTimestamp(),
    };

    if (isCod) {
      updateData['payment_status'] = 'PAID';
      updateData['cod_cash_collected'] = true;
    }

    await _firestore.collection('orders').doc(orderId).update(updateData);
    return true;
  }
}
