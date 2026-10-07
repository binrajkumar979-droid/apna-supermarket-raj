import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supermarket_app/config/app_config.dart';
import 'package:supermarket_app/core/models/order_model.dart';
import 'package:supermarket_app/localization/app_strings.dart';
import 'package:supermarket_app/features/customer/orders/data/order_repository.dart';
import 'package:supermarket_app/features/customer/orders/presentation/order_tracking_screen.dart';

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final ordersStream = ref.watch(orderRepositoryProvider).streamCustomerOrders('current_user');

    return Scaffold(
      appBar: AppBar(
        title: Text(lang == AppLanguage.hi ? 'मेरे ऑर्डर (Order History)' : 'My Orders'),
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: ordersStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data!;
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long_outlined, size: 70, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    lang == AppLanguage.hi ? 'आपने अभी तक कोई ऑर्डर नहीं दिया' : 'No past orders yet',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (c, i) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final order = orders[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => OrderTrackingScreen(orderId: order.orderId),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order #${order.orderNumber}',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppConfig.primaryColor),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: order.orderStatus == OrderStatus.cancelled
                                  ? AppConfig.errorColor.withOpacity(0.1)
                                  : AppConfig.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              lang == AppLanguage.hi ? order.orderStatus.labelHi : order.orderStatus.labelEn,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: order.orderStatus == OrderStatus.cancelled ? AppConfig.errorColor : AppConfig.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${order.items.length} ${lang == AppLanguage.hi ? "सामान" : "items"} | ${order.paymentMode == "COD" ? "Cash on Delivery" : "Online Paid"}',
                        style: const TextStyle(color: AppConfig.textSecondary, fontSize: 13),
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '₹${order.finalPayableAmount.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppConfig.textPrimary),
                          ),
                          Row(
                            children: [
                              Text(
                                lang == AppLanguage.hi ? 'ट्रैक करें' : 'Track Order',
                                style: const TextStyle(color: AppConfig.primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 14, color: AppConfig.primaryColor),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
