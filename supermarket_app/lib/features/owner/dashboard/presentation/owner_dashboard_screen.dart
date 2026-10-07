import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supermarket_app/config/app_config.dart';
import 'package:supermarket_app/core/models/order_model.dart';
import 'package:supermarket_app/core/services/sound_service.dart';
import 'package:supermarket_app/features/auth/presentation/auth_controller.dart';
import 'package:supermarket_app/features/owner/data/owner_repository.dart';
import 'package:supermarket_app/features/owner/orders/presentation/owner_order_detail_screen.dart';
import 'package:supermarket_app/features/owner/products/presentation/owner_product_list_screen.dart';
import 'package:supermarket_app/features/owner/products/presentation/add_edit_product_screen.dart';
import 'package:supermarket_app/features/owner/settings/presentation/owner_settings_screen.dart';

class OwnerDashboardScreen extends ConsumerStatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  ConsumerState<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends ConsumerState<OwnerDashboardScreen> {
  int _lastOrderCount = 0;

  @override
  Widget build(BuildContext context) {
    final liveOrdersStream = ref.watch(ownerRepositoryProvider).streamLiveOrders();

    return Scaffold(
      appBar: AppBar(
        title: const Text("दुकानदार पोर्टल (Store Owner)"),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined),
            tooltip: "सामान लिस्ट",
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (c) => const OwnerProductListScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: "सेटिंग्स",
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (c) => const OwnerSettingsScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "लॉगआउट",
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: liveOrdersStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allOrders = snapshot.data!;
          final newOrders = allOrders.where((o) => o.orderStatus == OrderStatus.placed).toList();
          final packingOrders = allOrders.where((o) => o.orderStatus == OrderStatus.confirmed || o.orderStatus == OrderStatus.packed).toList();
          final outOrders = allOrders.where((o) => o.orderStatus == OrderStatus.outForDelivery).toList();

          if (newOrders.length > _lastOrderCount && _lastOrderCount > 0) {
            SoundService.playNewOrderAlert();
          }
          _lastOrderCount = newOrders.length;

          double todaySales = 0;
          for (final o in allOrders) {
            if (o.orderStatus != OrderStatus.cancelled) {
              todaySales += o.finalPayableAmount;
            }
          }

          return DefaultTabController(
            length: 3,
            child: Column(
              children: [
                if (newOrders.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    color: Colors.red.shade700,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.notification_important, color: Colors.white, size: 24),
                            const SizedBox(width: 8),
                            Text(
                              "🚨 ${newOrders.length} नया आर्डर आया है!",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                        TextButton(
                          style: TextButton.styleFrom(backgroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 10)),
                          onPressed: () => SoundService.stopAlert(),
                          child: const Text("आवाज बंद करें", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),

                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.indigo.shade50,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("आज की कुल बिक्री", style: TextStyle(fontSize: 12, color: Colors.black54)),
                              const SizedBox(height: 4),
                              Text("₹${todaySales.toStringAsFixed(0)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.indigo)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("कुल आर्डर", style: TextStyle(fontSize: 12, color: Colors.black54)),
                              const SizedBox(height: 4),
                              Text("${allOrders.length}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.indigo)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  color: Colors.white,
                  child: TabBar(
                    labelColor: Colors.indigo,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.indigo,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    tabs: [
                      Tab(text: "नया आर्डर (${newOrders.length})"),
                      Tab(text: "पैक हो रहा (${packingOrders.length})"),
                      Tab(text: "डिलीवरी (${outOrders.length})"),
                    ],
                  ),
                ),

                Expanded(
                  child: TabBarView(
                    children: [
                      _buildOrdersList(newOrders, "कोई नया आर्डर नहीं है"),
                      _buildOrdersList(packingOrders, "कोई आर्डर पैकिंग में नहीं है"),
                      _buildOrdersList(outOrders, "कोई आर्डर रास्ते में नहीं है"),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigo,
        icon: const Icon(Icons.add_a_photo),
        label: const Text("नया सामान जोड़ें"),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (c) => const AddEditProductScreen()));
        },
      ),
    );
  }

  Widget _buildOrdersList(List<OrderModel> orders, String emptyMsg) {
    if (orders.isEmpty) {
      return Center(
        child: Text(emptyMsg, style: const TextStyle(color: Colors.grey, fontSize: 15)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: orders.length,
      separatorBuilder: (c, i) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final order = orders[index];

        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Order #${order.orderNumber}",
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.indigo),
                ),
                Text(
                  "₹${order.finalPayableAmount.toStringAsFixed(0)}",
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(
                  "${order.customerName} • Gaon: ${order.deliveryAddress['village'] ?? ''}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                ),
                Text(
                  "${order.items.length} सामान | ${order.paymentMode == 'COD' ? 'नकद (COD)' : 'Online Paid'}",
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                if (order.handwrittenListImageUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text("📷 पर्ची संलग्न है", style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.indigo),
            onTap: () {
              SoundService.stopAlert();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => OwnerOrderDetailScreen(initialOrder: order),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
