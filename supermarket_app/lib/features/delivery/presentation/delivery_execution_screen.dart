import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pinput/pinput.dart';
import 'package:supermarket_app/config/app_config.dart';
import 'package:supermarket_app/core/models/order_model.dart';
import 'package:supermarket_app/localization/app_strings.dart';
import 'package:supermarket_app/features/delivery/data/delivery_repository.dart';

class DeliveryExecutionScreen extends ConsumerStatefulWidget {
  final OrderModel order;

  const DeliveryExecutionScreen({super.key, required this.order});

  @override
  ConsumerState<DeliveryExecutionScreen> createState() => _DeliveryExecutionScreenState();
}

class _DeliveryExecutionScreenState extends ConsumerState<DeliveryExecutionScreen> {
  final TextEditingController _otpCtrl = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  void _onVerifyDeliveryPressed() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length != 4) {
      setState(() => _errorMessage = "कृपया ग्राहक से पूछकर 4 अंकों का OTP दर्ज करें");
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final success = await ref.read(deliveryRepositoryProvider).verifyOtpAndCompleteDelivery(
      orderId: widget.order.orderId,
      enteredOtp: otp,
      actualOtp: widget.order.deliveryOtp,
      isCod: widget.order.paymentMode == 'COD',
    );

    setState(() => _isSubmitting = false);

    if (success) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (c) => AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.check_circle, color: AppConfig.successColor, size: 28),
                SizedBox(width: 10),
                Text("डिलीवरी पूर्ण!"),
              ],
            ),
            content: Text(
              widget.order.paymentMode == 'COD'
                  ? "Order #${widget.order.orderNumber} सफलतापूर्वक डिलीवर हो गया और ₹${widget.order.finalPayableAmount.toStringAsFixed(0)} नकद राशि दर्ज हो गई।"
                  : "Order #${widget.order.orderNumber} सफलतापूर्वक डिलीवर हो गया।",
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(c);
                  Navigator.pop(context);
                },
                child: const Text("ठीक है (Done)"),
              ),
            ],
          ),
        );
      }
    } else {
      setState(() => _errorMessage = "गलत OTP! ग्राहक के फोन पर आया 4 अंकों का OTP डालें।");
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final isCod = order.paymentMode == 'COD';

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade300, width: 2),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text("Order #${order.orderNumber} डिलीवरी"),
        backgroundColor: Colors.teal.shade800,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isCod)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.green.shade600, width: 2),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.payments, color: Colors.green, size: 36),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "ग्राहक से नकद (COD) लें:",
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          Text(
                            "₹${order.finalPayableAmount.toStringAsFixed(0)}",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.green.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade300),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.check_circle_outline, color: Colors.blue, size: 24),
                    SizedBox(width: 10),
                    Text(
                      "यह आर्डर ऑनलाइन पहले से PAID है (कोई कैश न लें)",
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 13),
                    ),
                  ],
                ),
              ),

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
                    order.customerName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "गाँव: ${order.deliveryAddress['village'] ?? ''}",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal.shade800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${order.deliveryAddress['house_no'] ?? ''}, ${order.deliveryAddress['area'] ?? ''}",
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    "Landmark: ${order.deliveryAddress['landmark'] ?? ''}, Pincode: ${order.deliveryAddress['pincode'] ?? ''}",
                    style: const TextStyle(fontSize: 13, color: AppConfig.textSecondary),
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            minimumSize: const Size(double.infinity, 44),
                          ),
                          icon: const Icon(Icons.phone),
                          label: const Text("कॉल करें"),
                          onPressed: () => launchUrl(Uri.parse('tel:${order.customerPhone}')),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            minimumSize: const Size(double.infinity, 44),
                          ),
                          icon: const Icon(Icons.directions),
                          label: const Text("Maps रास्ता"),
                          onPressed: () {
                            final query = Uri.encodeComponent(
                              "${order.deliveryAddress['area']}, ${order.deliveryAddress['village']}, ${order.deliveryAddress['pincode']}",
                            );
                            launchUrl(Uri.parse("https://www.google.com/maps/search/?api=1&query=$query"));
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.teal.shade300, width: 1.5),
              ),
              child: Column(
                children: [
                  const Icon(Icons.lock_open, color: Colors.teal, size: 36),
                  const SizedBox(height: 8),
                  const Text(
                    "ग्राहक का 4-अंकों का डिलीवरी OTP दर्ज करें",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "सामान देने के बाद ग्राहक से OTP पूछकर डालें:",
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: Pinput(
                      length: 4,
                      controller: _otpCtrl,
                      defaultPinTheme: defaultPinTheme,
                      onCompleted: (pin) => _onVerifyDeliveryPressed(),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade800,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: _isSubmitting ? null : _onVerifyDeliveryPressed,
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            isCod ? "कैश प्राप्त हुआ और डिलीवरी पूर्ण करें" : "डिलीवरी पूर्ण करें (Confirm Delivery)",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

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
                  const Text("सामान की जांच (Item Checklist):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const Divider(height: 16),
                  ...order.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          const Icon(Icons.check_box_outlined, color: Colors.teal, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "${item.nameHi} (${item.variantName}) x${item.deliveredQuantity}",
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Text("₹${item.itemTotal.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
