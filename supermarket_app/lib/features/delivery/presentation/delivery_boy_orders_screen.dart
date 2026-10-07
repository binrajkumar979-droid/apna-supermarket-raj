import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supermarket_app/core/models/order_model.dart';
import 'package:supermarket_app/features/auth/presentation/auth_controller.dart';
import 'package:supermarket_app/features/delivery/data/delivery_repository.dart';
import 'package:supermarket_app/features/delivery/presentation/delivery_execution_screen.dart';

class DeliveryBoyOrdersScreen extends ConsumerWidget {
  const DeliveryBoyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignedStream = ref.watch(deliveryRepositoryProvider).streamAssignedOrders('current_delivery_boy');

    return Scaffold(
      appBar: AppBar(
        title: const Text("डिलीवरी साथी (Delivery Portal)"),
        backgroundColor: Colors.teal.shade800,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "लॉगआउट",
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: assignedStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data!;
          final activeOrders = orders.where((o) => o.orderStatus != OrderStatus.delivered && o.orderStatus != OrderStatus.cancelled).toList();
          final completedOrders = orders.where((o) => o.orderStatus == OrderStatus.delivered).toList();

          double todayCodCollected = 0;
          for (final o in completedOrders) {
            if (o.paymentMode == 'COD') {
              todayCodCollected += o.finalPayableAmount;
            }
          }

          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.teal.shade50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("आज का कुल COD कैश (दुकान पर जमा करने हेतु):", style: TextStyle(fontSize: 12, color: Colors.black87)),
                          const SizedBox(height: 2),
                          Text(
                            "₹${todayCodCollected.toStringAsFixed(0)}",
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.teal.shade900),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: Colors.teal.shade100, borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          "${completedOrders.length} पूर्ण",
                          style: TextStyle(color: Colors.teal.shade900, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  color: Colors.white,
                  child: TabBar(
                    labelColor: Colors.teal.shade800,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.teal.shade800,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    tabs: [
                      Tab(text: "चालू डिलीवरी (${activeOrders.length})"),
                      Tab(text: "पूर्ण डिलीवरी (${completedOrders.length})"),
                    ],
                  ),
                ),

                Expanded(
                  child: TabBarView(
                    children: [
                      _buildOrdersList(context, activeOrders, true),
                      _buildOrdersList(context, completedOrders, false),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrdersList(BuildContext context, List<OrderModel> orders, bool isActive) {
    if (orders.isEmpty) {
      return Center(
        child: Text(
          isActive ? "कोई चालू डिलीवरी नहीं है" : "कोई पूर्ण डिलीवरी नहीं है",
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: orders.length,
      separatorBuilder: (c, i) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = orders[index];
        final isCod = order.paymentMode == 'COD';

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Order #${order.orderNumber}",
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Colors.teal.shade900),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isCod ? Colors.green.shade100 : Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isCod ? "कैश लेना है: ₹${order.finalPayableAmount.toStringAsFixed(0)}" : "Online Paid ₹${order.finalPayableAmount.toStringAsFixed(0)}",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isCod ? Colors.green.shade900 : Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "ग्राहक: ${order.customerName}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  "गाँव: ${order.deliveryAddress['village']} (${order.deliveryAddress['house_no']}, ${order.deliveryAddress['area']})",
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.phone, color: Colors.green),
                      onPressed: () => launchUrl(Uri.parse('tel:${order.customerPhone}')),
                    ),
                    IconButton(
                      icon: const Icon(Icons.directions, color: Colors.blue),
                      onPressed: () {
                        final query = Uri.encodeComponent(
                          "${order.deliveryAddress['area']}, ${order.deliveryAddress['village']}, ${order.deliveryAddress['pincode']}",
                        );
                        launchUrl(Uri.parse("https://www.google.com/maps/search/?api=1&query=$query"));
                      },
                    ),
                    const Spacer(),
                    if (isActive)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade800),
                        icon: const Icon(Icons.lock_open, size: 16),
                        label: const Text("OTP डालें और सामान दें"),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (c) => DeliveryExecutionScreen(order: order),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
