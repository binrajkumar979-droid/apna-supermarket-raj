import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supermarket_app/config/app_config.dart';
import 'package:supermarket_app/core/models/product_model.dart';
import 'package:supermarket_app/localization/app_strings.dart';
import 'package:supermarket_app/features/customer/cart/cart_provider.dart';
import 'package:supermarket_app/features/customer/cart/presentation/cart_screen.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  late ProductVariant _selectedVariant;

  @override
  void initState() {
    super.initState();
    _selectedVariant = widget.product.variants.isNotEmpty
        ? widget.product.variants.first
        : ProductVariant(
            variantId: 'default',
            variantName: widget.product.unitType,
            mrp: widget.product.mrp,
            sellingPrice: widget.product.sellingPrice,
            stockQuantity: widget.product.stockQuantity,
          );
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final cartState = ref.watch(cartProvider);
    final cartKey = '${widget.product.id}_${_selectedVariant.variantId}';
    final quantityInCart = cartState.items[cartKey]?.quantity ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(lang == AppLanguage.hi ? widget.product.nameHi : widget.product.nameEn),
        actions: [
          IconButton(
            icon: Badge(
              label: Text('${cartState.totalItemCount}'),
              isLabelVisible: cartState.totalItemCount > 0,
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (c) => const CartScreen()));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: Colors.white,
              width: double.infinity,
              height: 280,
              child: CachedNetworkImage(
                imageUrl: widget.product.primaryImage,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 64),
              ),
            ),
            const Divider(height: 1),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang == AppLanguage.hi ? widget.product.nameHi : widget.product.nameEn,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppConfig.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lang == AppLanguage.hi ? widget.product.nameEn : widget.product.nameHi,
                    style: const TextStyle(fontSize: 14, color: AppConfig.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  if (widget.product.isLooseItem) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.shade700),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.scale, color: Colors.brown, size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              lang == AppLanguage.hi
                                  ? 'यह खुली वस्तु है। दुकान पर वास्तविक वजन तोलने के बाद बिल में थोड़ा अंतर हो सकता है।'
                                  : 'This is a loose item. Final bill will reflect actual weighed quantity upon packing.',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.brown),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (widget.product.variants.length > 1) ...[
                    Text(
                      lang == AppLanguage.hi ? 'पैकिंग साइज चुनें:' : 'Select Pack Size:',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      children: widget.product.variants.map((variant) {
                        final isSelected = _selectedVariant.variantId == variant.variantId;
                        return ChoiceChip(
                          label: Text('${variant.variantName} - ₹${variant.sellingPrice.toStringAsFixed(0)}'),
                          selected: isSelected,
                          selectedColor: AppConfig.primaryColor.withOpacity(0.15),
                          labelStyle: TextStyle(
                            color: isSelected ? AppConfig.primaryColor : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedVariant = variant);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${_selectedVariant.sellingPrice.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppConfig.primaryColor),
                      ),
                      if (_selectedVariant.mrp > _selectedVariant.sellingPrice) ...[
                        const SizedBox(width: 10),
                        Text(
                          'MRP ₹${_selectedVariant.mrp.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 15, color: Colors.grey, decoration: TextDecoration.lineThrough),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: AppConfig.secondaryColor, borderRadius: BorderRadius.circular(6)),
                          child: Text(
                            '${_selectedVariant.discountPercent.toStringAsFixed(0)}% छूट',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),

                  Text(
                    lang == AppLanguage.hi ? 'विवरण (Description)' : 'Product Details',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    lang == AppLanguage.hi
                        ? (widget.product.descriptionHi.isNotEmpty ? widget.product.descriptionHi : widget.product.descriptionEn)
                        : (widget.product.descriptionEn.isNotEmpty ? widget.product.descriptionEn : widget.product.descriptionHi),
                    style: const TextStyle(fontSize: 14, height: 1.5, color: AppConfig.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
        ),
        child: quantityInCart == 0
            ? ElevatedButton.icon(
                icon: const Icon(Icons.add_shopping_cart),
                label: Text(
                  lang == AppLanguage.hi ? 'कार्ट में जोड़ें' : 'Add to Cart',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  ref.read(cartProvider.notifier).addItem(widget.product, _selectedVariant);
                },
              )
            : Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppConfig.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, color: Colors.white),
                            onPressed: () {
                              ref.read(cartProvider.notifier).removeOrDecrement(widget.product, _selectedVariant);
                            },
                          ),
                          Text(
                            '$quantityInCart ${lang == AppLanguage.hi ? "जोड़ा गया" : "in cart"}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, color: Colors.white),
                            onPressed: () {
                              ref.read(cartProvider.notifier).addItem(widget.product, _selectedVariant);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
