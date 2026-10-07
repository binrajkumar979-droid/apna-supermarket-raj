import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supermarket_app/config/app_config.dart';
import 'package:supermarket_app/core/models/order_model.dart';
import 'package:supermarket_app/localization/app_strings.dart';
import 'package:supermarket_app/features/owner/data/owner_repository.dart';

class OwnerOrderDetailScreen extends ConsumerStatefulWidget {
  final OrderModel initialOrder;

  const OwnerOrderDetailScreen({super.key, required this.initialOrder});

  @override
  ConsumerState<OwnerOrderDetailScreen> createState() => _OwnerOrderDetailScreenState();
}

class _OwnerOrderDetailScreenState extends ConsumerState<OwnerOrderDetailScreen> {
  late OrderModel _currentOrder;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.initialOrder;
  }

  void _showEditItemDialog(OrderItemModel item, int index) {
    final qtyController = TextEditingController(text: '${item.deliveredQuantity}');
    final weightController = TextEditingController(text: item.actualWeight ?? '');
    final priceController = TextEditingController(text: item.unitPrice.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("सामान बदलें: ${item.nameHi}"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("पैकिंग / दिया गया वजन:"),
                const SizedBox(height: 6),
                TextField(
                  controller: weightController,
                  decoration: const InputDecoration(
                    hintText: "उदा. 960g, 1.95kg (तोला हुआ वजन)",
                    prefixIcon: Icon(Icons.scale),
                  ),
                ),
                const SizedBox(height: 14),
                const Text("मात्रा (Quantity):"),
                const SizedBox(height: 6),
                TextField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.numbers)),
                ),
                const SizedBox(height: 14),
                const Text("प्रति इकाई मूल्य (₹ Unit Price):"),
                const SizedBox(height: 6),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.currency_rupee)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(context);
                final updated = List<OrderItemModel>.from(_currentOrder.items);
                updated.removeAt(index);
                await ref.read(ownerRepositoryProvider).updateOrderItemsAndBill(
                  orderId: _currentOrder.orderId,
                  updatedItems: updated,
                  reason: "${item.nameHi} out of stock hone ke karan hataya gaya",
                );
                setState(() {
                  _currentOrder = OrderModel.fromMap({
                    ..._currentOrder.items.map((e) => e.toMap()).toList() as dynamic,
                  }, _currentOrder.orderId);
                });
              },
              child: const Text("हटाएं (Out of Stock)"),
            ),
            ElevatedButton(
              onPressed: () async {
                final newQty = int.tryParse(qtyController.text.trim()) ?? item.orderedQuantity;
                final newPrice = double.tryParse(priceController.text.trim()) ?? item.unitPrice;
                final newWeight = weightController.text.trim();

                final updatedItem = OrderItemModel(
                  productId: item.productId,
                  variantId: item.variantId,
                  nameEn: item.nameEn,
                  nameHi: item.nameHi,
                  variantName: item.variantName,
                  imageUrl: item.imageUrl,
                  unitPrice: newPrice,
                  orderedQuantity: item.orderedQuantity,
                  deliveredQuantity: newQty,
                  actualWeight: newWeight.isNotEmpty ? newWeight : null,
                  itemTotal: newPrice * newQty,
                  isLooseItem: item.isLooseItem,
                );

                final updatedList = List<OrderItemModel>.from(_currentOrder.items);
                updatedList[index] = updatedItem;

                Navigator.pop(context);
                await ref.read(ownerRepositoryProvider).updateOrderItemsAndBill(
                  orderId: _currentOrder.orderId,
                  updatedItems: updatedList,
                  reason: "Vajan ya quantity adjust ki gayi",
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("✓ Item update ho gaya aur bill recalculate ho gaya!")),
                );
              },
              child: const Text("सेव करें"),
            ),
          ],
        );
      },
    );
  }

  void _shareInvoiceOnWhatsApp() {
    final buffer = StringBuffer();
    buffer.writeln("🧾 *${AppConfig.storeName} - Bill Receipt*");
    buffer.writeln("Order: #${_currentOrder.orderNumber}");
    buffer.writeln("Grahak: ${_currentOrder.customerName}");
    buffer.writeln("Gaon: ${_currentOrder.deliveryAddress['village'] ?? ''}");
    buffer.writeln("--------------------------");
    for (final item in _currentOrder.items) {
      final weight = item.actualWeight != null ? " (${item.actualWeight})" : "";
      buffer.writeln("• ${item.nameHi} x${item.deliveredQuantity}$weight - ₹${item.itemTotal.toStringAsFixed(0)}");
    }
    buffer.writeln("--------------------------");
    buffer.writeln("Delivery: FREE");
    buffer.writeln("*Total Bill: ₹${_currentOrder.finalPayableAmount.toStringAsFixed(0)}*");
    buffer.writeln("Payment: ${_currentOrder.paymentMode == 'COD' ? 'Cash on Delivery' : 'Paid Online'}");
    buffer.writeln("FSSAI: ${AppConfig.fssaiLicenseNo}");
    buffer.writeln("\nDhanyawad! Phir aaiyega.");

    final text = Uri.encodeComponent(buffer.toString());
    launchUrl(Uri.parse("https://wa.me/?text=$text"));
  }

  @override
  Widget build(BuildContext context) {
    final order = _currentOrder;

    return Scaffold(
      appBar: AppBar(
        title: Text("Order #${order.orderNumber} विवरण"),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: "WhatsApp par bill bhejein",
            onPressed: _shareInvoiceOnWhatsApp,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        order.customerName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          order.paymentMode == 'COD' ? 'COD (नकद)' : 'Paid Online',
                          style: TextStyle(color: Colors.indigo.shade800, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    order.customerPhone,
                    style: const TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          minimumSize: const Size(120, 38),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        icon: const Icon(Icons.phone, size: 18),
                        label: const Text("कॉल करें"),
                        onPressed: () => launchUrl(Uri.parse('tel:${order.customerPhone}')),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          minimumSize: const Size(120, 38),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        icon: const Icon(Icons.chat, size: 18),
                        label: const Text("WhatsApp"),
                        onPressed: () => launchUrl(Uri.parse('https://wa.me/${order.customerPhone}?text=Namaste')),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.location_on, color: Colors.indigo),
                      SizedBox(width: 8),
                      Text("डिलीवरी का पता और गाँव", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const Divider(height: 16),
                  Text(
                    "गाँव: ${order.deliveryAddress['village'] ?? ''}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${order.deliveryAddress['house_no'] ?? ''}, ${order.deliveryAddress['area'] ?? ''}",
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    "Landmark: ${order.deliveryAddress['landmark'] ?? ''}, Pincode: ${order.deliveryAddress['pincode'] ?? ''}",
                    style: const TextStyle(fontSize: 13, color: AppConfig.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.map),
                    label: const Text("Google Maps में रास्ता देखें"),
                    onPressed: () {
                      final query = Uri.encodeComponent(
                        "${order.deliveryAddress['area']}, ${order.deliveryAddress['village']}, ${order.deliveryAddress['pincode']}",
                      );
                      launchUrl(Uri.parse("https://www.google.com/maps/search/?api=1&query=$query"));
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (order.handwrittenListImageUrl != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade400),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "📷 ग्राहक द्वारा भेजी गई पर्ची (Handwritten List):",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.brown),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        order.handwrittenListImageUrl!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorWidget: (c, e, s) => const Text("Image preview error"),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "पसंद: ${order.substitutionPreference == 'replace_with_similar' ? 'दूसरा मिलता-जुलता सामान दें' : 'सामान न मिलने पर बिल से हटा दें'}",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text("सामान की लिस्ट (Edit karne ke liye tap karein)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Icon(Icons.edit, size: 18, color: Colors.indigo),
                    ],
                  ),
                  const Divider(height: 16),
                  ...order.items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;

                    return InkWell(
                      onTap: () => _showEditItemDialog(item, index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.nameHi,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        "Qty: ${item.deliveredQuantity} (${item.variantName})",
                                        style: const TextStyle(fontSize: 12, color: AppConfig.textSecondary),
                                      ),
                                      if (item.actualWeight != null) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                          decoration: BoxDecoration(color: Colors.amber.shade200, borderRadius: BorderRadius.circular(4)),
                                          child: Text("तोला: ${item.actualWeight}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              "₹${item.itemTotal.toStringAsFixed(0)}",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                          ],
                        ),
                      ),
                    );
                  }),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("कुल फाइनल बिल:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                      Text(
                        "₹${order.finalPayableAmount.toStringAsFixed(0)}",
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.indigo),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text("ऑर्डर स्टेटस बदलें:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800),
                    onPressed: () async {
                      await ref.read(ownerRepositoryProvider).updateOrderStatus(order.orderId, OrderStatus.confirmed);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order Confirmed!")));
                    },
                    child: const Text("1. स्वीकार करें"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800),
                    onPressed: () async {
                      await ref.read(ownerRepositoryProvider).updateOrderStatus(order.orderId, OrderStatus.packed);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order Marked Packed!")));
                    },
                    child: const Text("2. पैक हो गया"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade800),
              icon: const Icon(Icons.delivery_dining),
              label: const Text("3. डिलीवरी के लिए रवाना करें (Assign Delivery)"),
              onPressed: () async {
                await ref.read(ownerRepositoryProvider).assignDeliveryBoy(
                  orderId: order.orderId,
                  deliveryBoyId: "del_boy_1",
                  deliveryBoyName: "Sonu Pal (Delivery Boy)",
                  deliveryBoyPhone: "+919876543210",
                );
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Delivery Boy assigned!")));
              },
            ),
          ],
        ),
      ),
    );
  }
}
