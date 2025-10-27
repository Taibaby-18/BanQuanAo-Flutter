import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';

import '../models/product.dart';
import '../models/cart_item.dart';

import 'cart_screen.dart';
import 'orders_screen.dart';
import 'report_screen.dart';
import '../widgets/checkout_sheet.dart' show CheckoutSheet, CheckoutInput, PaymentMethodUI;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pp = context.read<ProductProvider>();
      pp.loadCategories();
      pp.loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<ProductProvider>();
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("POS Bán hàng"),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrdersScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.insights),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportScreen()),
            ),
          ),
          Stack(children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              ),
            ),
            if (cart.items.isNotEmpty)
              Positioned(
                right: 8,
                top: 8,
                child: CircleAvatar(
                  radius: 8,
                  child: Text("${cart.items.length}", style: const TextStyle(fontSize: 10)),
                ),
              ),
          ]),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                      (route) => false,
                );
              }
            },
          ),
        ],
      ),

      body: Column(
        children: [
          // ===== Search + Filter =====
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: "Tìm theo tên/SKU...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Lọc nâng cao',
                      icon: const Icon(Icons.tune),
                      onPressed: () async {
                        final result = await showModalBottomSheet<_FilterResult>(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => FilterSheet(
                            minPrice: pp.minPrice,
                            maxPrice: pp.maxPrice,
                            sort: pp.sort,
                          ),
                        );
                        if (result != null) {
                          await context.read<ProductProvider>().loadProducts(
                            minPrice: result.minPrice,
                            maxPrice: result.maxPrice,
                            sort: result.sort,
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () async {
                        _search.clear();
                        pp.clearFilters();
                        await context.read<ProductProvider>().loadProducts();
                      },
                    ),
                  ],
                ),
              ),
              onSubmitted: (txt) async {
                await context
                    .read<ProductProvider>()
                    .loadProducts(query: txt.trim().isEmpty ? null : txt.trim());
              },
            ),
          ),

          // ===== Category + Refresh =====
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    isExpanded: true,
                    value: pp.categoryId ?? 0,
                    items: pp.categories
                        .map((c) => DropdownMenuItem<int>(value: c.id, child: Text(c.name)))
                        .toList(),
                    onChanged: (v) async =>
                        context.read<ProductProvider>().loadProducts(categoryId: v),
                    decoration: const InputDecoration(
                      labelText: "Danh mục",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text("Tải lại"),
                  onPressed: () => context.read<ProductProvider>().loadProducts(),
                ),
              ],
            ),
          ),

          // ===== Grid products =====
          Expanded(
            child: pp.loading
                ? const Center(child: CircularProgressIndicator())
                : GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(12),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: .78,
              children: pp.products.map((p) => _ProductTile(p)).toList(),
            ),
          ),

          // ===== Pagination =====
          if (!pp.loading)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Text("Trang ${pp.page} / ${pp.totalPages} • ${pp.total} sp"),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Trang trước',
                    icon: const Icon(Icons.chevron_left),
                    onPressed: pp.page > 1
                        ? () => context.read<ProductProvider>().loadProducts(page: pp.page - 1)
                        : null,
                  ),
                  IconButton(
                    tooltip: 'Trang sau',
                    icon: const Icon(Icons.chevron_right),
                    onPressed: pp.page < pp.totalPages
                        ? () => context.read<ProductProvider>().loadProducts(page: pp.page + 1)
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),

      // ===== Bottom: thanh toán =====
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                "Tổng: ${cart.total.toStringAsFixed(0)} đ",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.point_of_sale),
              label: const Text("Thanh toán"),
              onPressed: cart.items.isEmpty
                  ? null
                  : () async {
                // Mở sheet nhập KH + chọn phương thức thanh toán
                final result = await showModalBottomSheet<CheckoutInput>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const CheckoutSheet(),
                );
                if (result == null) return;

                try {
                  final methodStr =
                  result.paymentMethod == PaymentMethodUI.transfer ? "Transfer" : "Cash";

                  final id = await context.read<CartProvider>().checkoutWithCustomer(
                    customerName: result.name,
                    customerPhone: result.phone,
                    printReceipt: result.printReceipt,
                    payNow: true,
                    paymentMethod: methodStr, // truyền xuống provider
                  );

                  if (context.mounted) {
                    final label = result.paymentMethod == PaymentMethodUI.transfer
                        ? "CHUYỂN KHOẢN"
                        : "TIỀN MẶT";
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Đã lập hóa đơn #$id (đã thanh toán $label)")),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text("Thanh toán lỗi: $e")));
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ====== Tile sản phẩm ======
class _ProductTile extends StatelessWidget {
  final Product p;
  const _ProductTile(this.p);

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          Expanded(
            child: p.imageUrl == null
                ? const Center(child: Icon(Icons.image, size: 56))
                : Image.network(p.imageUrl!, fit: BoxFit.cover, width: double.infinity),
          ),
          ListTile(
            title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text("${p.price.toStringAsFixed(0)} đ • Tồn: ${p.stock}"),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              children: [
                Expanded(child: Text("SKU: ${p.sku}", overflow: TextOverflow.ellipsis)),
                IconButton(
                  tooltip: "Thêm 1",
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    final cart = context.read<CartProvider>();
                    cart.add(CartItem(product: p, quantity: 1));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Đã thêm vào giỏ"), duration: Duration(milliseconds: 700)),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ====== Filter (giá + sắp xếp) ======
class _FilterResult {
  final double? minPrice, maxPrice;
  final String? sort; // name_asc | name_desc | price_asc | price_desc
  _FilterResult({this.minPrice, this.maxPrice, this.sort});
}

class FilterSheet extends StatefulWidget {
  final double? minPrice, maxPrice;
  final String? sort;
  const FilterSheet({super.key, this.minPrice, this.maxPrice, this.sort});

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  RangeValues _range = const RangeValues(0, 500000);
  String? _sort;

  @override
  void initState() {
    super.initState();
    _sort = widget.sort ?? 'name_asc';
    if (widget.minPrice != null || widget.maxPrice != null) {
      _range = RangeValues(
        (widget.minPrice ?? 0).toDouble(),
        (widget.maxPrice ?? 500000).toDouble(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Material(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Bộ lọc", style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Khoảng giá: ${_range.start.toStringAsFixed(0)} – ${_range.end.toStringAsFixed(0)} đ"),
                  TextButton(
                    onPressed: () => setState(() => _range = const RangeValues(0, 500000)),
                    child: const Text("Mặc định"),
                  ),
                ],
              ),
              RangeSlider(
                min: 0,
                max: 1000000,
                divisions: 100,
                values: _range,
                onChanged: (v) => setState(() => _range = v),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _sort,
                items: const [
                  DropdownMenuItem(value: 'name_asc', child: Text('Tên A→Z')),
                  DropdownMenuItem(value: 'name_desc', child: Text('Tên Z→A')),
                  DropdownMenuItem(value: 'price_asc', child: Text('Giá tăng dần')),
                  DropdownMenuItem(value: 'price_desc', child: Text('Giá giảm dần')),
                ],
                onChanged: (v) => setState(() => _sort = v),
                decoration: const InputDecoration(labelText: 'Sắp xếp'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Huỷ'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                          _FilterResult(
                            minPrice: _range.start <= 0 ? null : _range.start,
                            maxPrice: _range.end >= 1000000 ? null : _range.end,
                            sort: _sort,
                          ),
                        );
                      },
                      child: const Text('Áp dụng'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
