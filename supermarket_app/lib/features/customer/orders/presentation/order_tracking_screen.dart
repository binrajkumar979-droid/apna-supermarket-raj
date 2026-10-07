import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supermarket_app/config/app_config.dart';
import 'package:supermarket_app/core/models/order_model.dart';
import 'package:supermarket_app/localization/app_strings.dart';
import 'package:supermarket_app/features/customer/orders/data/order_repository.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  Timer? _countdownTimer;
  int _remainingSeconds = 300;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _countdownTimer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _showCancelDialog(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Order Cancel Karein?"),
          content: const Text("Kya aap sach me is order ko cancel karna chahte hain?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Nahi"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppConfig.errorColor),
              onPressed: () async {
                Navigator.pop(context);
                await ref.read(orderRepositoryProvider).cancelOrder(widget.orderId, "Customer cancelled within 5 mins");
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Order cancel kar diya gaya hai")),
                );
              },
              child: const Text("Haan, Cancel Karo"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final orderStream = ref.watch(orderRepositoryProvider).streamOrder(widget.orderId);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang == AppLanguage.hi ? 'ऑर्डर की स्थिति (Live Tracking)' : 'Order Tracking'),
      ),
      body: StreamBuilder<OrderModel>(
        stream: orderStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final order = snapshot.data!;
          final isCancelAllowed = order.canBeCancelled && _remainingSeconds > 0;

          return SingleChildScrollView(
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${order.orderNumber}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppConfig.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lang == AppLanguage.hi ? order.orderStatus.labelHi : order.orderStatus.labelEn,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: order.orderStatus == OrderStatus.cancelled
                                  ? AppConfig.errorColor
                                  : AppConfig.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppConfig.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          order.paymentMode == 'COD' ? 'Cash on Delivery' : 'Online Paid',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppConfig.primaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (order.orderStatus != OrderStatus.cancelled && order.orderStatus != OrderStatus.delivered) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'सुरक्षित डिलीवरी OTP',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          order.deliveryOtp,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 6,
                            color: Color(0xFF78350F),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          lang == AppLanguage.hi
                              ? 'सामान मिलने पर डिलीवरी बॉय को यह OTP बताएं'
                              : 'Share this 4-digit code with delivery person upon receiving goods',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (isCancelAllowed) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined, color: AppConfig.errorColor, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lang == AppLanguage.hi
                                    ? 'ऑर्डर कैंसिल समय शेष: ${_remainingSeconds ~/ 60}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}'
                                    : 'Cancel window: ${_remainingSeconds ~/ 60}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppConfig.errorColor),
                              ),
                              Text(
                                lang == AppLanguage.hi ? '5 मिनट के भीतर कभी भी रद्द करें' : 'You can cancel within 5 minutes',
                                style: const TextStyle(fontSize: 11, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppConfig.errorColor,
                            side: const BorderSide(color: AppConfig.errorColor),
                            minimumSize: const Size(80, 36),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          onPressed: () => _showCancelDialog(order),
                          child: Text(lang == AppLanguage.hi ? 'रद्द करें' : 'Cancel'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang == AppLanguage.hi ? 'डिलीवरी प्रोग्रेस' : 'Delivery Progress',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      _buildStep(
                        title: lang == AppLanguage.hi ? 'ऑर्डर प्राप्त हुआ' : 'Order Placed',
                        subtitle: 'Store received your order',
                        isCompleted: true,
                        isActive: order.orderStatus == OrderStatus.placed,
                      ),
                      _buildStep(
                        title: lang == AppLanguage.hi ? 'स्वीकार किया (Confirmed)' : 'Store Confirmed',
                        subtitle: 'Kirana owner is preparing bill',
                        isCompleted: order.orderStatus.index >= OrderStatus.confirmed.index,
                        isActive: order.orderStatus == OrderStatus.confirmed,
                      ),
                      _buildStep(
                        title: lang == AppLanguage.hi ? 'सामान पैक हुआ' : 'Items Packed',
                        subtitle: 'Weighed & packed neatly',
                        isCompleted: order.orderStatus.index >= OrderStatus.packed.index,
                        isActive: order.orderStatus == OrderStatus.packed,
                      ),
                      _buildStep(
                        title: lang == AppLanguage.hi ? 'डिलीवरी के लिए निकला' : 'Out for Delivery',
                        subtitle: order.assignedDeliveryBoyName != null
                            ? 'Delivering by: ${order.assignedDeliveryBoyName}'
                            : 'On the way to your village',
                        isCompleted: order.orderStatus.index >= OrderStatus.outForDelivery.index,
                        isActive: order.orderStatus == OrderStatus.outForDelivery,
                      ),
                      _buildStep(
                        title: lang == AppLanguage.hi ? 'सफलतापूर्वक डिलीवर' : 'Delivered',
                        subtitle: 'Delivered at your home',
                        isCompleted: order.orderStatus == OrderStatus.delivered,
                        isActive: order.orderStatus == OrderStatus.delivered,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.phone),
                        label: Text(lang == AppLanguage.hi ? 'दुकानदार को कॉल' : 'Call Store'),
                        onPressed: () => launchUrl(Uri.parse('tel:${AppConfig.supportPhone}')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
                        icon: const Icon(Icons.chat),
                        label: const Text('WhatsApp'),
                        onPressed: () => launchUrl(
                          Uri.parse('https://wa.me/${AppConfig.supportWhatsApp}?text=Hello, I need help with Order #${order.orderNumber}'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang == AppLanguage.hi ? 'ऑर्डर किया गया सामान' : 'Ordered Items',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const Divider(height: 20),
                      ...order.items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${lang == AppLanguage.hi ? item.nameHi : item.nameEn} (${item.variantName}) x ${item.orderedQuantity}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              Text(
                                '₹${item.itemTotal.toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      }),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(lang == AppLanguage.hi ? 'डिलीवरी' : 'Delivery'),
                          const Text('FREE', style: TextStyle(color: AppConfig.successColor, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            lang == AppLanguage.hi ? 'कुल बिल' : 'Total Bill',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            '₹${order.finalPayableAmount.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppConfig.primaryColor),
                          ),
                        ],
                      ),
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

  Widget _buildStep({
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isActive,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: isCompleted ? AppConfig.primaryColor : Colors.grey.shade300,
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : const SizedBox.shrink(),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? AppConfig.primaryColor : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                  color: isActive || isCompleted ? AppConfig.textPrimary : Colors.grey,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: isCompleted ? AppConfig.textSecondary : Colors.grey),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}
