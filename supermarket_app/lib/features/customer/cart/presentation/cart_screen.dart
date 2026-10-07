import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supermarket_app/config/app_config.dart';
import 'package:supermarket_app/localization/app_strings.dart';
import 'package:supermarket_app/features/customer/cart/cart_provider.dart';
import 'package:supermarket_app/features/customer/address/presentation/village_selector_screen.dart';
import 'package:supermarket_app/features/customer/checkout/presentation/checkout_screen.dart';
import 'package:supermarket_app/features/customer/list_upload/presentation/upload_list_screen.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final cartState = ref.watch(cartProvider);
    final selectedAddress = ref.watch(selectedAddressProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get('cart', lang)),
        actions: [
          if (cartState.items.isNotEmpty || cartState.handwrittenListImageUrl != null)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear Cart',
              onPressed: () {
                ref.read(cartProvider.notifier).clearCart();
              },
            ),
        ],
      ),
      body: (cartState.items.isEmpty && cartState.handwrittenListImageUrl == null)
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_basket_outlined, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    lang == AppLanguage.hi ? 'आपका थैला खाली है' : 'Your cart is empty',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lang == AppLanguage.hi ? 'दुकान से अपनी पसंद का सामान जोड़ें' : 'Add groceries from the store',
                    style: const TextStyle(color: AppConfig.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(minimumSize: const Size(200, 48)),
                    icon: const Icon(Icons.document_scanner),
                    label: Text(lang == AppLanguage.hi ? 'पर्ची अपलोड करें' : 'Upload List Photo'),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (c) => const UploadListScreen()));
                    },
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!cartState.meetsMinOrder && cartState.items.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber.shade400),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              AppStrings.get('min_order_msg', lang).replaceAll(
                                '{amount}',
                                cartState.amountNeededForMinOrder.toStringAsFixed(0),
                              ),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (cartState.handwrittenListImageUrl != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppConfig.primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppConfig.primaryColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(cartState.handwrittenListImageUrl!),
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang == AppLanguage.hi ? '✓ हाथ से लिखी पर्ची जुड़ी हुई है' : '✓ Handwritten List Attached',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  lang == AppLanguage.hi ? 'दुकानदार इसे देखकर सामान जोड़ेंगे' : 'Store will pack as per list',
                                  style: const TextStyle(fontSize: 12, color: AppConfig.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => ref.read(cartProvider.notifier).setHandwrittenListImage(null),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cartState.items.values.length,
                    separatorBuilder: (c, i) => const Divider(height: 24),
                    itemBuilder: (context, index) {
                      final item = cartState.items.values.elementAt(index);
                      return Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: item.product.primaryImage,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang == AppLanguage.hi ? item.product.nameHi : item.product.nameEn,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  item.variant.variantName,
                                  style: const TextStyle(fontSize: 12, color: AppConfig.textSecondary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₹${item.totalPrice.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: AppConfig.primaryColor,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppConfig.primaryColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.remove, color: Colors.white, size: 16),
                                  onPressed: () {
                                    ref.read(cartProvider.notifier).removeOrDecrement(item.product, item.variant);
                                  },
                                ),
                                Text(
                                  '${item.quantity}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.add, color: Colors.white, size: 16),
                                  onPressed: () {
                                    ref.read(cartProvider.notifier).addItem(item.product, item.variant);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  if (cartState.hasLooseItems) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.scale_outlined, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              lang == AppLanguage.hi
                                  ? 'आपके कार्ट में खुली वस्तुएं (loose items) हैं। डिलीवरी पर वास्तविक वजन के अनुसार बिल में थोड़ा फर्क हो सकता है।'
                                  : 'Contains loose items. Actual weight will be confirmed upon packaging.',
                              style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.w500),
                            ),
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
                          lang == AppLanguage.hi ? 'बिल का विवरण (Bill Summary)' : 'Bill Summary',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(lang == AppLanguage.hi ? 'सामान का कुल मूल्य' : 'Item Total'),
                            Text('₹${cartState.subtotal.toStringAsFixed(0)}'),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(lang == AppLanguage.hi ? 'डिलीवरी चार्ज' : 'Delivery Fee'),
                            const Text(
                              'FREE',
                              style: TextStyle(color: AppConfig.successColor, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        if (cartState.totalSavings > 0) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                lang == AppLanguage.hi ? 'आपकी कुल बचत' : 'Your Total Savings',
                                style: const TextStyle(color: AppConfig.successColor, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '- ₹${cartState.totalSavings.toStringAsFixed(0)}',
                                style: const TextStyle(color: AppConfig.successColor, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              lang == AppLanguage.hi ? 'कुल देय राशि' : 'To Pay',
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
                ],
              ),
            ),
      bottomNavigationBar: (cartState.items.isNotEmpty || cartState.handwrittenListImageUrl != null)
          ? Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: ElevatedButton(
                onPressed: (cartState.items.isEmpty && cartState.handwrittenListImageUrl == null) ||
                        (!cartState.meetsMinOrder && cartState.handwrittenListImageUrl == null)
                    ? null
                    : () {
                        if (selectedAddress == null) {
                          Navigator.push(context, MaterialPageRoute(builder: (c) => const VillageAddressScreen()));
                        } else {
                          Navigator.push(context, MaterialPageRoute(builder: (c) => const CheckoutScreen()));
                        }
                      },
                child: Text(
                  selectedAddress == null
                      ? (lang == AppLanguage.hi ? 'गाँव और पता चुनें' : 'Select Village & Address')
                      : (lang == AppLanguage.hi ? 'ऑर्डर आगे बढ़ाएं (Checkout)' : 'Proceed to Checkout'),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            )
          : null,
    );
  }
}
