import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supermarket_app/config/app_config.dart';
import 'package:supermarket_app/localization/app_strings.dart';
import 'package:supermarket_app/features/customer/cart/cart_provider.dart';

class UploadListScreen extends ConsumerStatefulWidget {
  const UploadListScreen({super.key});

  @override
  ConsumerState<UploadListScreen> createState() => _UploadListScreenState();
}

class _UploadListScreenState extends ConsumerState<UploadListScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  String _substitutionChoice = 'replace_with_similar';

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint("Error picking list image: $e");
    }
  }

  void _onUploadConfirm() {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kripya parchi ki photo kheenchiye ya chunein")),
      );
      return;
    }

    ref.read(cartProvider.notifier).setHandwrittenListImage(_selectedImage!.path);
    ref.read(cartProvider.notifier).setSubstitutionPreference(_substitutionChoice);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppConfig.successColor,
        content: Text("✓ Parchi safaltapurvak jud gayi hai! Dukandaar ise dekhkar samaan pack karenge."),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang == AppLanguage.hi ? 'हाथ से लिखी पर्ची भेजें' : 'Upload Handwritten List'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppConfig.primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppConfig.primaryColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.document_scanner_outlined, color: AppConfig.primaryColor, size: 36),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang == AppLanguage.hi ? 'कागज पर लिखी पर्ची की फोटो' : 'Paper Grocery List Photo',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lang == AppLanguage.hi
                                ? 'कागज पर लिखे सामान की फोटो खींचें, दुकानदार खुद सारा सामान पैक करके बिल बना देंगे।'
                                : 'Take a clear picture of your handwritten ration list. Store owner will pack and generate your bill.',
                            style: const TextStyle(fontSize: 13, color: AppConfig.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (_selectedImage != null) ...[
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        _selectedImage!,
                        height: 260,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    IconButton(
                      icon: const CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, color: Colors.white),
                      ),
                      onPressed: () => setState(() => _selectedImage = null),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ] else ...[
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_a_photo_outlined, size: 48, color: AppConfig.primaryColor),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(130, 44),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            icon: const Icon(Icons.camera_alt, size: 18),
                            label: Text(lang == AppLanguage.hi ? 'कैमरा' : 'Camera'),
                            onPressed: () => _pickImage(ImageSource.camera),
                          ),
                          const SizedBox(width: 14),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(130, 44),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                            icon: const Icon(Icons.photo_library, size: 18),
                            label: Text(lang == AppLanguage.hi ? 'गैलरी' : 'Gallery'),
                            onPressed: () => _pickImage(ImageSource.gallery),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              Text(
                lang == AppLanguage.hi ? 'अगर कोई सामान न मिले तो क्या करें?' : 'If an item is out of stock?',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              RadioListTile<String>(
                value: 'replace_with_similar',
                groupValue: _substitutionChoice,
                title: Text(lang == AppLanguage.hi ? 'मिलता-जुलता दूसरा ब्रांड दें' : 'Replace with similar item/brand'),
                onChanged: (v) => setState(() => _substitutionChoice = v!),
              ),
              RadioListTile<String>(
                value: 'remove_item',
                groupValue: _substitutionChoice,
                title: Text(lang == AppLanguage.hi ? 'वह सामान हटा दें (पैसे कम कर दें)' : 'Remove item from bill'),
                onChanged: (v) => setState(() => _substitutionChoice = v!),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _onUploadConfirm,
                child: Text(
                  lang == AppLanguage.hi ? 'पर्ची जोड़ें और कार्ट में जाएं' : 'Attach List & View Cart',
                  style: const TextStyle(fontSize: 17),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
