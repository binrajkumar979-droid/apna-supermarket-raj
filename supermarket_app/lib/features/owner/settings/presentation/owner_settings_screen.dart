import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supermarket_app/config/app_config.dart';
import 'package:supermarket_app/core/services/battery_service.dart';
import 'package:supermarket_app/features/owner/data/owner_repository.dart';

class OwnerSettingsScreen extends ConsumerStatefulWidget {
  const OwnerSettingsScreen({super.key});

  @override
  ConsumerState<OwnerSettingsScreen> createState() => _OwnerSettingsScreenState();
}

class _OwnerSettingsScreenState extends ConsumerState<OwnerSettingsScreen> {
  bool _isStoreOpen = true;
  final TextEditingController _closedMsgCtrl = TextEditingController(text: "दुकान कल सुबह 7:00 बजे खुलेगी");
  final TextEditingController _minOrderCtrl = TextEditingController(text: "300");
  final TextEditingController _deliveryFeeCtrl = TextEditingController(text: "0");
  final TextEditingController _cancelWindowCtrl = TextEditingController(text: "5");
  final TextEditingController _fssaiCtrl = TextEditingController(text: AppConfig.fssaiLicenseNo);

  @override
  void dispose() {
    _closedMsgCtrl.dispose();
    _minOrderCtrl.dispose();
    _deliveryFeeCtrl.dispose();
    _cancelWindowCtrl.dispose();
    _fssaiCtrl.dispose();
    super.dispose();
  }

  void _onSaveSettings() {
    ref.read(ownerRepositoryProvider).setStoreOpenStatus(_isStoreOpen, _closedMsgCtrl.text.trim());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppConfig.successColor,
        content: Text("✓ Dukan ki settings update ho gayi!"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("दुकान सेटिंग्स (Store Settings)"),
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isStoreOpen ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _isStoreOpen ? Colors.green.shade300 : Colors.red.shade300),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isStoreOpen ? Icons.storefront : Icons.store_mall_directory_outlined,
                            color: _isStoreOpen ? Colors.green.shade800 : Colors.red.shade800,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _isStoreOpen ? "दुकान खुली है (Open)" : "दुकान बंद है (Closed)",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _isStoreOpen ? Colors.green.shade900 : Colors.red.shade900,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: _isStoreOpen,
                        activeColor: Colors.green,
                        onChanged: (val) => setState(() => _isStoreOpen = val),
                      ),
                    ],
                  ),
                  if (!_isStoreOpen) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _closedMsgCtrl,
                      decoration: const InputDecoration(
                        labelText: "दुकान बंद का संदेश (ग्राहकों को दिखेगा)",
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            InkWell(
              onTap: () => BatteryOptimizationHelper.showBatteryOptimizationDialog(context),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.battery_saver, color: Colors.orange, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Battery Saver Guide (अति आवश्यक)",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            "नए आर्डर का अलर्ट कभी मिस न हो, इसके लिए सेटिंग्स देखें",
                            style: TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.orange),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text("व्यापार नियम (Business Rules):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),

            TextFormField(
              controller: _deliveryFeeCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "डिलीवरी चार्ज (₹ Delivery Fee)",
                hintText: "0 (डिफ़ॉल्ट रूप से फ्री)",
                prefixIcon: Icon(Icons.local_shipping_outlined),
              ),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _minOrderCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "कम से कम आर्डर राशि (₹ Minimum Order Value)",
                hintText: "300",
                prefixIcon: Icon(Icons.shopping_cart_checkout),
              ),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _cancelWindowCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "आर्डर कैंसिल समय सीमा (मिनट)",
                hintText: "5",
                prefixIcon: Icon(Icons.timer_outlined),
              ),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _fssaiCtrl,
              decoration: const InputDecoration(
                labelText: "FSSAI लाइसेंस नंबर (बिल पर अनिवार्य)",
                prefixIcon: Icon(Icons.verified_outlined),
              ),
            ),
            const SizedBox(height: 28),

            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              onPressed: _onSaveSettings,
              child: const Text("सेटिंग्स सुरक्षित करें (Save Settings)", style: TextStyle(fontSize: 17)),
            ),
          ],
        ),
      ),
    );
  }
}
