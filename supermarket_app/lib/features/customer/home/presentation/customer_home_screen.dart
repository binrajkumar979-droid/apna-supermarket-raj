import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supermarket_app/config/app_config.dart';
import 'package:supermarket_app/core/models/product_model.dart';
import 'package:supermarket_app/core/services/voice_service.dart';
import 'package:supermarket_app/localization/app_strings.dart';
import 'package:supermarket_app/features/customer/address/presentation/village_selector_screen.dart';
import 'package:supermarket_app/features/customer/cart/cart_provider.dart';
import 'package:supermarket_app/features/customer/cart/presentation/cart_screen.dart';
import 'package:supermarket_app/features/customer/catalog/data/product_repository.dart';
import 'package:supermarket_app/features/customer/catalog/presentation/widgets/product_card.dart';
import 'package:supermarket_app/features/customer/list_upload/presentation/upload_list_screen.dart';
import 'package:supermarket_app/features/customer/orders/presentation/order_history_screen.dart';

final selectedCategoryProvider = StateProvider<String?>((ref) => null);
final searchQueryProvider = StateProvider<String>((ref) => '');

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final VoiceSearchService _voiceService = VoiceSearchService();
  bool _isListening = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onVoiceSearchPressed() {
    if (_isListening) {
      _voiceService.stopListening();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      _voiceService.startListening(
        onResult: (spokenText) {
          _searchCtrl.text = spokenText;
          ref.read(searchQueryProvider.notifier).state = spokenText;
          setState(() => _isListening = false);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final selectedAddress = ref.watch(selectedAddressProvider);
    final cartState = ref.watch(cartProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    final categoriesStream = ref.watch(productRepositoryProvider).streamCategories();
    final trendingStream = ref.watch(productRepositoryProvider).streamTrendingProducts();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: InkWell(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (c) => const VillageAddressScreen()));
          },
          child: Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedAddress == null
                          ? (lang == AppLanguage.hi ? 'गाँव चुनें' : 'Select Village')
                          : selectedAddress.villageName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      selectedAddress == null
                          ? (lang == AppLanguage.hi ? 'डिलीवरी के लिए गाँव सेट करें' : 'Set delivery location')
                          : selectedAddress.areaMohalla,
                      style: const TextStyle(fontSize: 11, color: Colors.white70),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined, color: Colors.white),
            tooltip: 'My Orders',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (c) => const OrderHistoryScreen()));
            },
          ),
          IconButton(
            icon: Badge(
              label: Text('${cartState.totalItemCount}'),
              isLabelVisible: cartState.totalItemCount > 0,
              child: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (c) => const CartScreen()));
            },
          ),
          TextButton(
            onPressed: () => ref.read(languageProvider.notifier).toggleLanguage(),
            child: Text(
              lang == AppLanguage.hi ? 'EN' : 'हिंदी',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppConfig.primaryColor,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (val) => ref.read(searchQueryProvider.notifier).state = val,
                  decoration: InputDecoration(
                    hintText: AppStrings.get('search_hint', lang),
                    hintStyle: const TextStyle(fontSize: 14, color: AppConfig.textSecondary),
                    prefixIcon: const Icon(Icons.search, color: AppConfig.primaryColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening ? Colors.red : AppConfig.primaryColor,
                      ),
                      onPressed: _onVoiceSearchPressed,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (c) => const UploadListScreen()));
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppConfig.primaryColor.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 22,
                        child: Icon(Icons.edit_document, color: AppConfig.primaryColor, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang == AppLanguage.hi ? 'कागज की पर्ची से ऑर्डर करें' : 'Order via Handwritten List',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              lang == AppLanguage.hi ? 'फोटो खींचें, दुकानदार सामान पैक करेंगे' : 'Upload photo & we pack for you',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
            ),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppConfig.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_shipping, color: AppConfig.successColor, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    lang == AppLanguage.hi ? 'सभी आर्डरों पर डिलीवरी बिल्कुल FREE' : 'FREE Home Delivery on every order',
                    style: const TextStyle(color: AppConfig.successColor, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                lang == AppLanguage.hi ? 'कैटेगरी (श्रेणियां)' : 'Categories',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppConfig.textPrimary),
              ),
            ),
            StreamBuilder<List<CategoryModel>>(
              stream: categoriesStream,
              builder: (context, snapshot) {
                final categories = snapshot.data ?? [];
                if (categories.isEmpty) return const SizedBox.shrink();

                return SizedBox(
                  height: 105,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length + 1,
                    separatorBuilder: (c, i) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        final isAll = selectedCategory == null;
                        return InkWell(
                          onTap: () => ref.read(selectedCategoryProvider.notifier).state = null,
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: isAll ? AppConfig.primaryColor : Colors.grey[200],
                                child: Icon(Icons.grid_view, color: isAll ? Colors.white : Colors.black87),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                lang == AppLanguage.hi ? 'सभी' : 'All',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isAll ? FontWeight.bold : FontWeight.normal,
                                  color: isAll ? AppConfig.primaryColor : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final cat = categories[index - 1];
                      final isSelected = selectedCategory == cat.id;

                      return InkWell(
                        onTap: () => ref.read(selectedCategoryProvider.notifier).state = cat.id,
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundImage: CachedNetworkImageProvider(cat.imageUrl),
                              child: isSelected
                                  ? Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: AppConfig.primaryColor, width: 3),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 70,
                              child: Text(
                                lang == AppLanguage.hi ? cat.nameHi : cat.nameEn,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? AppConfig.primaryColor : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Text(
                searchQuery.isNotEmpty
                    ? (lang == AppLanguage.hi ? 'खोज परिणाम ("$searchQuery")' : 'Search Results ("$searchQuery")')
                    : (lang == AppLanguage.hi ? 'लोकप्रिय किराना सामान' : 'Popular Kirana Items'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppConfig.textPrimary),
              ),
            ),
            StreamBuilder<List<ProductModel>>(
              stream: trendingStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
                }

                var products = snapshot.data!;
                if (selectedCategory != null) {
                  products = products.where((p) => p.categoryId == selectedCategory).toList();
                }

                if (searchQuery.isNotEmpty) {
                  products = ref.read(productRepositoryProvider).searchProducts(searchQuery, products);
                }

                if (products.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        lang == AppLanguage.hi ? 'कोई सामान नहीं मिला' : 'No products found',
                        style: const TextStyle(color: AppConfig.textSecondary, fontSize: 15),
                      ),
                    ),
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return ProductCard(product: products[index]);
                  },
                );
              },
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: cartState.totalItemCount > 0
          ? Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppConfig.primaryColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${cartState.totalItemCount} ${lang == AppLanguage.hi ? "सामान" : "items"} | ₹${cartState.subtotal.toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        AppStrings.get('delivery_free', lang),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppConfig.primaryColor,
                      minimumSize: const Size(120, 42),
                    ),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (c) => const CartScreen()));
                    },
                    child: Row(
                      children: [
                        Text(
                          lang == AppLanguage.hi ? 'थैला देखें' : 'View Cart',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
