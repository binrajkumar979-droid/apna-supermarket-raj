import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supermarket_app/config/app_config.dart';
import 'package:supermarket_app/core/models/product_model.dart';
import 'package:supermarket_app/features/owner/data/owner_repository.dart';

class AddEditProductScreen extends ConsumerStatefulWidget {
  final ProductModel? existingProduct;

  const AddEditProductScreen({super.key, this.existingProduct});

  @override
  ConsumerState<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameHiCtrl = TextEditingController();
  final TextEditingController _nameEnCtrl = TextEditingController();
  final TextEditingController _barcodeCtrl = TextEditingController();
  final TextEditingController _mrpCtrl = TextEditingController();
  final TextEditingController _sellingPriceCtrl = TextEditingController();
  final TextEditingController _costPriceCtrl = TextEditingController();
  final TextEditingController _stockCtrl = TextEditingController();
  final TextEditingController _searchKeywordsCtrl = TextEditingController();

  String _unitType = 'kg';
  String _categoryId = 'cat_staples';
  bool _isLooseItem = false;
  bool _isInStock = true;
  File? _productPhoto;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.existingProduct != null) {
      final p = widget.existingProduct!;
      _nameHiCtrl.text = p.nameHi;
      _nameEnCtrl.text = p.nameEn;
      _barcodeCtrl.text = p.barcode;
      _mrpCtrl.text = p.mrp.toStringAsFixed(0);
      _sellingPriceCtrl.text = p.sellingPrice.toStringAsFixed(0);
      _costPriceCtrl.text = p.costPrice.toStringAsFixed(0);
      _stockCtrl.text = '${p.stockQuantity}';
      _searchKeywordsCtrl.text = p.alternateSearchTerms.join(', ');
      _unitType = p.unitType;
      _categoryId = p.categoryId;
      _isLooseItem = p.isLooseItem;
      _isInStock = p.isInStock;
    }
  }

  @override
  void dispose() {
    _nameHiCtrl.dispose();
    _nameEnCtrl.dispose();
    _barcodeCtrl.dispose();
    _mrpCtrl.dispose();
    _sellingPriceCtrl.dispose();
    _costPriceCtrl.dispose();
    _stockCtrl.dispose();
    _searchKeywordsCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, maxWidth: 1000, maxHeight: 1000, imageQuality: 85);
    if (picked != null) {
      setState(() => _productPhoto = File(picked.path));
    }
  }

  void _openBarcodeScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SizedBox(
          height: 400,
          child: Column(
            children: [
              AppBar(
                title: const Text("बारकोड स्कैन करें"),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              Expanded(
                child: MobileScanner(
                  onDetect: (capture) {
                    final barcodes = capture.barcodes;
                    for (final b in barcodes) {
                      if (b.rawValue != null) {
                        setState(() => _barcodeCtrl.text = b.rawValue!);
                        Navigator.pop(context);
                        break;
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onSaveProduct() async {
    if (_formKey.currentState!.validate()) {
      final mrp = double.parse(_mrpCtrl.text.trim());
      final selling = double.parse(_sellingPriceCtrl.text.trim());
      final cost = double.tryParse(_costPriceCtrl.text.trim()) ?? 0.0;
      final stock = int.tryParse(_stockCtrl.text.trim()) ?? 10;
      final keywords = _searchKeywordsCtrl.text
          .split(',')
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toList();

      final newProduct = ProductModel(
        id: widget.existingProduct?.id ?? 'prod_${DateTime.now().millisecondsSinceEpoch}',
        barcode: _barcodeCtrl.text.trim(),
        categoryId: _categoryId,
        nameEn: _nameEnCtrl.text.trim(),
        nameHi: _nameHiCtrl.text.trim(),
        alternateSearchTerms: keywords,
        images: widget.existingProduct?.images ?? [
          'https://images.unsplash.com/photo-1542838132-92c53300491e?w=500&auto=format&fit=crop&q=80'
        ],
        isLooseItem: _isLooseItem,
        costPrice: cost,
        mrp: mrp,
        sellingPrice: selling,
        unitType: _unitType,
        stockQuantity: stock,
        isInStock: _isInStock,
        variants: [
          ProductVariant(
            variantId: 'var_1',
            variantName: '1 $_unitType',
            mrp: mrp,
            sellingPrice: selling,
            stockQuantity: stock,
          ),
        ],
      );

      await ref.read(ownerRepositoryProvider).saveProduct(newProduct);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppConfig.successColor,
          content: Text("✓ Samaan dukan me jud gaya!"),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingProduct == null ? "नया सामान जोड़ें (Add Product)" : "सामान एडिट करें"),
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: InkWell(
                  onTap: () => _pickPhoto(ImageSource.camera),
                  child: Container(
                    height: 140,
                    width: 140,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.indigo.shade300, width: 1.5),
                    ),
                    child: _productPhoto != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(_productPhoto!, fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.add_a_photo, size: 36, color: Colors.indigo),
                              SizedBox(height: 6),
                              Text("फोटो खींचें", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _barcodeCtrl,
                      decoration: const InputDecoration(
                        labelText: "बारकोड (Barcode)",
                        hintText: "उदा. 8901234567890",
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      minimumSize: const Size(60, 52),
                    ),
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text("स्कैन"),
                    onPressed: _openBarcodeScanner,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameHiCtrl,
                decoration: const InputDecoration(
                  labelText: "सामान का हिंदी नाम *",
                  hintText: "उदा. आशीर्वाद चक्की आटा 5kg",
                ),
                validator: (v) => v == null || v.trim().isEmpty ? "Hindi naam zaroori hai" : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameEnCtrl,
                decoration: const InputDecoration(
                  labelText: "English Name *",
                  hintText: "e.g. Aashirvaad Chakki Atta 5kg",
                ),
                validator: (v) => v == null || v.trim().isEmpty ? "English name zaroori hai" : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _mrpCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "MRP ₹ *"),
                      validator: (v) => v == null || v.trim().isEmpty ? "MRP dalein" : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _sellingPriceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "दुकान रेट ₹ *"),
                      validator: (v) => v == null || v.trim().isEmpty ? "Rate dalein" : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _costPriceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "खरीद मूल्य ₹"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _unitType,
                      decoration: const InputDecoration(labelText: "इकाई (Unit)"),
                      items: const [
                        DropdownMenuItem(value: 'kg', child: Text("kg (किलो)")),
                        DropdownMenuItem(value: 'g', child: Text("g (ग्राम)")),
                        DropdownMenuItem(value: 'litre', child: Text("Litre (लीटर)")),
                        DropdownMenuItem(value: 'packet', child: Text("Packet (पैकेट)")),
                        DropdownMenuItem(value: 'piece', child: Text("Piece (पीस)")),
                      ],
                      onChanged: (v) => setState(() => _unitType = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _stockCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "स्टॉक मात्रा"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _isLooseItem,
                activeColor: Colors.indigo,
                title: const Text("⚖️ यह खुली वस्तु है (Loose item - वजन तोलकर दिया जाएगा)"),
                subtitle: const Text("जैसे खुली चीनी, दाल, आलू, प्याज"),
                onChanged: (v) => setState(() => _isLooseItem = v ?? false),
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _searchKeywordsCtrl,
                decoration: const InputDecoration(
                  labelText: "सर्च शब्द (Keywords)",
                  hintText: "उदा. chini, sugar, shakkar, khuli chini",
                ),
              ),
              const SizedBox(height: 28),

              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                onPressed: _onSaveProduct,
                child: const Text("दुकान में सुरक्षित करें (Save Product)", style: TextStyle(fontSize: 17)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
