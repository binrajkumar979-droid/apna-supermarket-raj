import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supermarket_app/core/models/product_model.dart';
import 'package:supermarket_app/features/customer/catalog/data/product_repository.dart';
import 'package:supermarket_app/features/owner/data/owner_repository.dart';
import 'package:supermarket_app/features/owner/products/presentation/add_edit_product_screen.dart';

class OwnerProductListScreen extends ConsumerStatefulWidget {
  const OwnerProductListScreen({super.key});

  @override
  ConsumerState<OwnerProductListScreen> createState() => _OwnerProductListScreenState();
}

class _OwnerProductListScreenState extends ConsumerState<OwnerProductListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsStream = ref.watch(productRepositoryProvider).streamTrendingProducts();

    return Scaffold(
      appBar: AppBar(
        title: const Text("दुकान का सामान (Product Catalog)"),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, size: 28),
            tooltip: "नया सामान जोड़ें",
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (c) => const AddEditProductScreen()));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.indigo.shade50,
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: "सामान का नाम या बारकोड खोजें...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<List<ProductModel>>(
              stream: productsStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var products = snapshot.data!;
                if (_searchQuery.isNotEmpty) {
                  products = products.where((p) {
                    return p.nameHi.toLowerCase().contains(_searchQuery) ||
                        p.nameEn.toLowerCase().contains(_searchQuery) ||
                        p.barcode.contains(_searchQuery);
                  }).toList();
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: products.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final product = products[index];

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: product.primaryImage,
                                width: 55,
                                height: 55,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.nameHi,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Text(
                                    "${product.nameEn} • MRP: ₹${product.mrp.toStringAsFixed(0)}",
                                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        "रेट: ₹${product.sellingPrice.toStringAsFixed(0)}",
                                        style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.indigo),
                                      ),
                                      if (product.isLooseItem) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                          decoration: BoxDecoration(color: Colors.amber.shade200, borderRadius: BorderRadius.circular(4)),
                                          child: const Text("खुला सामान", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            Switch(
                              value: product.isInStock,
                              activeColor: Colors.green,
                              onChanged: (val) {
                                ref.read(ownerRepositoryProvider).toggleProductStock(product.id, val);
                              },
                            ),

                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.indigo, size: 20),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (c) => AddEditProductScreen(existingProduct: product),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigo,
        icon: const Icon(Icons.add),
        label: const Text("सामान जोड़ें"),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (c) => const AddEditProductScreen()));
        },
      ),
    );
  }
}
