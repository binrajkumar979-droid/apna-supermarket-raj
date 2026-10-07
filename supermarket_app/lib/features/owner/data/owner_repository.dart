import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supermarket_app/core/models/order_model.dart';
import 'package:supermarket_app/core/models/product_model.dart';

final ownerRepositoryProvider = Provider<OwnerRepository>((ref) {
  return OwnerRepository();
});

class OwnerRepository {
  final FirebaseFirestore _firestore;

  OwnerRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<OrderModel>> streamLiveOrders() {
    return _firestore
        .collection('orders')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => OrderModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    await _firestore.collection('orders').doc(orderId).update({
      'order_status': newStatus.name.toUpperCase(),
    });
  }

  Future<void> assignDeliveryBoy({
    required String orderId,
    required String deliveryBoyId,
    required String deliveryBoyName,
    required String deliveryBoyPhone,
  }) async {
    await _firestore.collection('orders').doc(orderId).update({
      'assigned_delivery_boy_id': deliveryBoyId,
      'assigned_delivery_boy_name': deliveryBoyName,
      'assigned_delivery_boy_phone': deliveryBoyPhone,
      'order_status': 'OUT_FOR_DELIVERY',
    });
  }

  Future<void> updateOrderItemsAndBill({
    required String orderId,
    required List<OrderItemModel> updatedItems,
    required String reason,
  }) async {
    double newItemTotal = 0;
    for (final item in updatedItems) {
      newItemTotal += item.itemTotal;
    }

    final orderRef = _firestore.collection('orders').doc(orderId);
    final orderDoc = await orderRef.get();
    final oldTotal = (orderDoc.data()?['bill_summary']?['final_payable_amount'] as num?)?.toDouble() ?? 0.0;

    await orderRef.update({
      'items': updatedItems.map((i) => i.toMap()).toList(),
      'bill_summary.item_total': newItemTotal,
      'bill_summary.final_payable_amount': newItemTotal,
      'edit_history': FieldValue.arrayUnion([
        {
          'edited_by': 'Owner',
          'reason': reason,
          'timestamp': Timestamp.now(),
          'old_total': oldTotal,
          'new_total': newItemTotal,
        }
      ]),
    });
  }

  Future<void> saveProduct(ProductModel product) async {
    final docRef = _firestore.collection('products').doc(product.id.isEmpty ? null : product.id);
    final data = product.toMap();
    data['updated_at'] = FieldValue.serverTimestamp();
    if (product.id.isEmpty) {
      data['created_at'] = FieldValue.serverTimestamp();
      await docRef.set(data);
    } else {
      await docRef.set(data, SetOptions(merge: true));
    }
  }

  Future<void> toggleProductStock(String productId, bool isInStock) async {
    await _firestore.collection('products').doc(productId).update({
      'is_in_stock': isInStock,
    });
  }

  Future<void> deleteProduct(String productId) async {
    await _firestore.collection('products').doc(productId).delete();
  }

  Future<void> setStoreOpenStatus(bool isOpen, String? closedMessage) async {
    await _firestore.collection('store_config').doc('settings').set({
      'is_store_open': isOpen,
      'closed_message_hi': closedMessage ?? 'Dukan abhi band hai',
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamStoreSettings() {
    return _firestore.collection('store_config').doc('settings').snapshots();
  }
}
