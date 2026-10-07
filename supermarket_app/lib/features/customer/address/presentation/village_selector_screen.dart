import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supermarket_app/config/app_config.dart';
import 'package:supermarket_app/core/models/address_model.dart';
import 'package:supermarket_app/localization/app_strings.dart';

final selectedAddressProvider = StateProvider<AddressModel?>((ref) => null);

class VillageAddressScreen extends ConsumerStatefulWidget {
  const VillageAddressScreen({super.key});

  @override
  ConsumerState<VillageAddressScreen> createState() => _VillageAddressScreenState();
}

class _VillageAddressScreenState extends ConsumerState<VillageAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  final List<VillageModel> _availableVillages = [
    VillageModel(id: 'vlg_rampur', nameEn: 'Rampur', nameHi: 'रामपुर', pincode: '244901', block: 'Bilaspur', district: 'Rampur'),
    VillageModel(id: 'vlg_shahpur', nameEn: 'Shahpur', nameHi: 'शाहपुर', pincode: '244901', block: 'Bilaspur', district: 'Rampur'),
    VillageModel(id: 'vlg_kalyanpur', nameEn: 'Kalyanpur', nameHi: 'कल्याणपुर', pincode: '244923', block: 'Milak', district: 'Rampur'),
    VillageModel(id: 'vlg_madhupur', nameEn: 'Madhupur', nameHi: 'मधुपुर', pincode: '244901', block: 'Bilaspur', district: 'Rampur'),
  ];

  VillageModel? _selectedVillage;
  final TextEditingController _houseNoCtrl = TextEditingController();
  final TextEditingController _areaCtrl = TextEditingController();
  final TextEditingController _landmarkCtrl = TextEditingController();
  final TextEditingController _pincodeCtrl = TextEditingController();

  @override
  void dispose() {
    _houseNoCtrl.dispose();
    _areaCtrl.dispose();
    _landmarkCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  void _onSaveAddress() {
    if (_formKey.currentState!.validate()) {
      if (_selectedVillage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Kripya apna gaon (village) chunein")),
        );
        return;
      }

      final newAddress = AddressModel(
        id: 'addr_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'current_user',
        isDefault: true,
        houseNo: _houseNoCtrl.text.trim(),
        villageId: _selectedVillage!.id,
        villageName: _selectedVillage!.nameHi,
        areaMohalla: _areaCtrl.text.trim(),
        landmark: _landmarkCtrl.text.trim(),
        postOffice: _selectedVillage!.nameHi,
        block: _selectedVillage!.block,
        district: _selectedVillage!.district,
        pincode: _pincodeCtrl.text.trim().isNotEmpty ? _pincodeCtrl.text.trim() : _selectedVillage!.pincode,
      );

      ref.read(selectedAddressProvider.notifier).state = newAddress;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang == AppLanguage.hi ? 'डिलीवरी पता और गाँव' : 'Delivery Address & Village'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppConfig.primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppConfig.primaryColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: AppConfig.primaryColor, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          lang == AppLanguage.hi
                              ? 'हम आपके गाँव में घर तक फ्री डिलीवरी करते हैं।'
                              : 'We deliver FREE to your doorstep in serviceable villages.',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  lang == AppLanguage.hi ? 'अपना गाँव चुनें *' : 'Select Your Village *',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<VillageModel>(
                  value: _selectedVillage,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.home_work_outlined),
                    hintText: lang == AppLanguage.hi ? 'गाँव की सूची में से चुनें' : 'Choose from village list',
                  ),
                  items: _availableVillages.map((v) {
                    return DropdownMenuItem<VillageModel>(
                      value: v,
                      child: Text(
                        lang == AppLanguage.hi ? '${v.nameHi} (${v.nameEn})' : '${v.nameEn} (${v.pincode})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedVillage = val;
                      if (val != null) {
                        _pincodeCtrl.text = val.pincode;
                      }
                    });
                  },
                ),
                const SizedBox(height: 10),

                if (_selectedVillage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppConfig.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: AppConfig.successColor, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            lang == AppLanguage.hi
                                ? '✓ ${_selectedVillage!.nameHi} में डिलीवरी उपलब्ध है (अनुमानित ${_selectedVillage!.estimatedDeliveryMins} मिनट)'
                                : '✓ Delivery Available in ${_selectedVillage!.nameEn} (~${_selectedVillage!.estimatedDeliveryMins} mins)',
                            style: const TextStyle(color: AppConfig.successColor, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                TextFormField(
                  controller: _houseNoCtrl,
                  decoration: InputDecoration(
                    labelText: lang == AppLanguage.hi ? 'मकान नंबर / घर की पहचान *' : 'House No / Home Landmark *',
                    hintText: lang == AppLanguage.hi ? 'उदा. प्रधान जी के घर के पास' : 'e.g. Near Pradhan Ji House',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Kripya ghar ki pehchan likhein' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _areaCtrl,
                  decoration: InputDecoration(
                    labelText: lang == AppLanguage.hi ? 'मोहल्ला / टोला / गली *' : 'Mohalla / Tola / Street *',
                    hintText: lang == AppLanguage.hi ? 'उदा. ब्राह्मण टोला, बाजार वाली गली' : 'e.g. Market Wali Gali',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Kripya mohalla likhein' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _landmarkCtrl,
                  decoration: InputDecoration(
                    labelText: lang == AppLanguage.hi ? 'मशहूर लैंडमार्क (मन्दिर, स्कूल, पानी की टंकी)' : 'Famous Landmark *',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Kripya landmark likhein' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _pincodeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: lang == AppLanguage.hi ? 'पिनकोड (Pincode)' : 'Pincode',
                  ),
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _onSaveAddress,
                  child: Text(
                    lang == AppLanguage.hi ? 'पता सुरक्षित करें और आगे बढ़ें' : 'Save Address & Proceed',
                    style: const TextStyle(fontSize: 17),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
