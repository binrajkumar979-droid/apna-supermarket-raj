import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supermarket_app/config/app_config.dart';
import 'package:supermarket_app/core/models/product_model.dart';
import 'package:supermarket_app/localization/app_strings.dart';
import 'package:supermarket_app/features/customer/cart/cart_provider.dart';
import 'package:supermarket_app/features/customer/catalog/presentation/product_detail_screen.dart';

class ProductCard extends ConsumerWidget {
  final ProductModel product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final cartState = ref.watch(cartProvider);

    final selectedVariant = product.variants.isNotEmpty
        ? product.variants.first
        : ProductVariant(
            variantId: 'default',
            variantName: product.unitType,
            mrp: product.mrp,
            sellingPrice: product.sellingPrice,
            stockQuantity: product.stockQuantity,
          );

    final cartKey = '${product.id}_${selectedVariant.variantId}';
    final cartItem = cartState.items[cartKey];
    final quantityInCart = cartItem?.quantity ?? 0;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  child: AspectRatio(
                    aspectRatio: 1.2,
                    child: CachedNetworkImage(
                      imageUrl: product.primaryImage,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey[200]),
                      errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                    ),
                  ),
                ),
                if (selectedVariant.discountPercent > 0)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppConfig.secondaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${selectedVariant.discountPercent.toStringAsFixed(0)}% OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (product.isLooseItem)
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        lang == AppLanguage.hi ? '⚖️ वजन अनुसार' : '⚖️ By Weight',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang == AppLanguage.hi ? product.nameHi : product.nameEn,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppConfig.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedVariant.variantName,
                    style: const TextStyle(fontSize: 12, color: AppConfig.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '₹${selectedVariant.sellingPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppConfig.primaryColor,
                        ),
                      ),
                      if (selectedVariant.mrp > selectedVariant.sellingPrice) ...[
                        const SizedBox(width: 6),
                        Text(
                          '₹${selectedVariant.mrp.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  quantityInCart == 0
                      ? SizedBox(
                          width: double.infinity,
                          height: 36,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppConfig.primaryColor,
                              side: const BorderSide(color: AppConfig.primaryColor, width: 1.5),
                              elevation: 0,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              ref.read(cartProvider.notifier).addItem(product, selectedVariant);
                            },
                            child: Text(
                              lang == AppLanguage.hi ? '+ जोड़ें' : '+ ADD',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                          ),
                        )
                      : Container(
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppConfig.primaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, color: Colors.white, size: 18),
                                onPressed: () {
                                  ref.read(cartProvider.notifier).removeOrDecrement(product, selectedVariant);
                                },
                              ),
                              Text(
                                '$quantityInCart',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                                onPressed: () {
                                  ref.read(cartProvider.notifier).addItem(product, selectedVariant);
                                },
                              ),
                            ],
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
