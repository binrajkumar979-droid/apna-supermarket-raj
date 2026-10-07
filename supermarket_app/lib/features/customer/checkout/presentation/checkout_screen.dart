import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supermarket_app/config/app_config.dart';
import 'package:supermarket_app/core/services/payment_service.dart';
import 'package:supermarket_app/localization/app_strings.dart';
import 'package:supermarket_app/features/customer/address/presentation/village_selector_screen.dart';
import 'package:supermarket_app/features/customer/cart/cart_provider.dart';
import 'package:supermarket_app/features/customer/orders/data/order_repository.dart';
import 'package:supermarket_app/features/customer/orders/presentation/order_tracking_screen.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String _paymentMode = 'COD';
  String _deliverySlot = 'ASAP';
  bool _isSubmitting = false;
  late PaymentService _paymentService;

  @override
  void initState() {
    super.initState();
    _paymentService = PaymentService();
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  void _onPlaceOrderPressed() async {
    if (_isSubmitting) return;

    final selectedAddress = ref.read(selectedAddressProvider);
    if (selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kripya pehle delivery gaon aur pata chunein")),
      );
      Navigator.push(context, MaterialPageRoute(builder: (c) => const VillageAddressScreen()));
      return;
    }

    final cartState = ref.read(cartProvider);
    if (cartState.items.isEmpty && cartState.handwrittenListImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Aapka cart khali hai")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final itemsPayload = cartState.items.values.map((item) {
        return {
          'product_id': item.product.id,
          'variant_id': item.variant.variantId,
          'name_en': item.product.nameEn,
          'name_hi': item.product.nameHi,
          'variant_name': item.variant.variantName,
          'image_url': item.product.primaryImage,
          'unit_price': item.variant.sellingPrice,
          'quantity': item.quantity,
          'is_loose_item': item.product.isLooseItem,
        };
      }).toList();

      final orderResult = await ref.read(orderRepositoryProvider).createOrder(
        items: itemsPayload,
        deliveryAddress: selectedAddress.toMap(),
        paymentMode: _paymentMode,
        substitutionPreference: cartState.substitutionPreference,
        handwrittenListImageUrl: cartState.handwrittenListImageUrl,
        deliverySlot: _deliverySlot,
      );

      final orderId = orderResult['order_id'] as String;
      final razorpayOrderId = orderResult['razorpay_order_id'] as String?;
      final razorpayKey = orderResult['razorpay_key_id'] as String? ?? 'rzp_test_mock';

      if (_paymentMode == 'ONLINE_RAZORPAY' && razorpayOrderId != null) {
        _paymentService.openCheckout(
          razorpayKey: razorpayKey,
          razorpayOrderId: razorpayOrderId,
          amount: cartState.finalTotal,
          customerPhone: '+919999999999',
          customerName: 'Customer',
          onSuccess: (resp) async {
            await ref.read(orderRepositoryProvider).verifyPayment(
              orderId: orderId,
              razorpayOrderId: resp.orderId ?? razorpayOrderId,
              razorpayPaymentId: resp.paymentId ?? '',
              razorpaySignature: resp.signature ?? '',
            );

            _finishAndNavigateToTracking(orderId);
          },
          onFailure: (err) {
            setState(() => _isSubmitting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Payment radd ho gaya: ${err.message ?? 'Try again'}")),
            );
          },
          onExternalWallet: (resp) {
            _finishAndNavigateToTracking(orderId);
          },
        );
      } else {
        _finishAndNavigateToTracking(orderId);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Order darj karne me truti hui: $e")),
      );
    }
  }

  void _finishAndNavigateToTracking(String orderId) {
    ref.read(cartProvider.notifier).clearCart();
    setState(() => _isSubmitting = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => OrderTrackingScreen(orderId: orderId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final selectedAddress = ref.watch(selectedAddressProvider);
    final cartState = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang == AppLanguage.hi ? 'ऑर्डर की पुष्टि (Checkout)' : 'Checkout'),
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
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: AppConfig.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            lang == AppLanguage.hi ? 'डिलीवरी का पता' : 'Delivery Address',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (c) => const VillageAddressScreen()));
                        },
                        child: Text(lang == AppLanguage.hi ? 'बदलें' : 'Change'),
                      ),
                    ],
                  ),
                  const Divider(height: 12),
                  if (selectedAddress != null) ...[
                    Text(
                      'गाँव: ${selectedAddress.villageName}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppConfig.primaryColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${selectedAddress.houseNo}, ${selectedAddress.areaMohalla}',
                      style: const TextStyle(fontSize: 14, color: AppConfig.textPrimary),
                    ),
                    Text(
                      'Landmark: ${selectedAddress.landmark}, Pincode: ${selectedAddress.pincode}',
                      style: const TextStyle(fontSize: 12, color: AppConfig.textSecondary),
                    ),
                  ] else ...[
                    Text(
                      lang == AppLanguage.hi ? 'कृपया अपना गाँव और घर का पता चुनें' : 'Please select delivery address',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),

            Text(
              lang == AppLanguage.hi ? 'डिलीवरी का समय चुनें:' : 'Select Delivery Slot:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _deliverySlot = 'ASAP'),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _deliverySlot == 'ASAP' ? AppConfig.primaryColor.withOpacity(0.1) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _deliverySlot == 'ASAP' ? AppConfig.primaryColor : const Color(0xFFCBD5E1),
                          width: _deliverySlot == 'ASAP' ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.flash_on, color: Colors.amber, size: 28),
                          const SizedBox(height: 4),
                          Text(
                            lang == AppLanguage.hi ? 'जल्द से जल्द' : 'Fast Delivery',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const Text('~45 mins', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _deliverySlot = 'EVENING'),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _deliverySlot == 'EVENING' ? AppConfig.primaryColor.withOpacity(0.1) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _deliverySlot == 'EVENING' ? AppConfig.primaryColor : const Color(0xFFCBD5E1),
                          width: _deliverySlot == 'EVENING' ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.nightlight_round, color: Colors.indigo, size: 28),
                          const SizedBox(height: 4),
                          Text(
                            lang == AppLanguage.hi ? 'शाम को' : 'Evening Slot',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const Text('5:00 - 8:00 PM', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Text(
              lang == AppLanguage.hi ? 'भुगतान का तरीका (Payment Mode):' : 'Payment Mode:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Column(
                children: [
                  RadioListTile<String>(
                    value: 'COD',
                    groupValue: _paymentMode,
                    activeColor: AppConfig.primaryColor,
                    secondary: const Icon(Icons.money, color: Colors.green, size: 28),
                    title: Text(
                      lang == AppLanguage.hi ? 'सामान मिलने पर नकद (Cash on Delivery)' : 'Cash on Delivery (COD)',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Text(
                      lang == AppLanguage.hi ? 'घर पर सामान आने पर पैसे दें' : 'Pay when groceries arrive',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onChanged: (val) => setState(() => _paymentMode = val!),
                  ),
                  const Divider(height: 1),
                  RadioListTile<String>(
                    value: 'ONLINE_RAZORPAY',
                    groupValue: _paymentMode,
                    activeColor: AppConfig.primaryColor,
                    secondary: const Icon(Icons.qr_code_2, color: AppConfig.primaryColor, size: 28),
                    title: Text(
                      lang == AppLanguage.hi ? 'ऑनलाइन / UPI (Google Pay, PhonePe, Paytm)' : 'Online UPI / Card / QR',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: Text(
                      lang == AppLanguage.hi ? 'सुरक्षित ऑनलाइन भुगतान' : 'Fast & secure digital payment',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onChanged: (val) => setState(() => _paymentMode = val!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

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
                  Text(
                    lang == AppLanguage.hi ? 'बिल सारांश (Bill Summary)' : 'Bill Summary',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(lang == AppLanguage.hi ? 'सामान का मूल्य' : 'Subtotal'),
                      Text('₹${cartState.subtotal.toStringAsFixed(0)}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(lang == AppLanguage.hi ? 'डिलीवरी शुल्क' : 'Delivery Fee'),
                      const Text('FREE', style: TextStyle(color: AppConfig.successColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        lang == AppLanguage.hi ? 'कुल भुगतान' : 'Grand Total',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Text(
                        '₹${cartState.finalTotal.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: AppConfig.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            ElevatedButton(
              onPressed: _isSubmitting ? null : _onPlaceOrderPressed,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text(
                      _paymentMode == 'COD'
                          ? (lang == AppLanguage.hi ? 'ऑर्डर कन्फर्म करें (₹${cartState.finalTotal.toStringAsFixed(0)})' : 'Place Order (₹${cartState.finalTotal.toStringAsFixed(0)})')
                          : (lang == AppLanguage.hi ? 'ऑनलाइन भुगतान करें (₹${cartState.finalTotal.toStringAsFixed(0)})' : 'Pay Online (₹${cartState.finalTotal.toStringAsFixed(0)})'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
