import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

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

    final theme = Theme.of(context);
    final primary = const Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: primary,
        title: Row(
          children: [
            Image.asset('assets/images/hutech_logo.png', height: 28),
            const SizedBox(width: 8),
            const Text("POS Bán hàng HUTECH", style: TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long, color: Colors.white),
            tooltip: 'Đơn hàng',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrdersScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.insights, color: Colors.white),
            tooltip: 'Thống kê',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportScreen()),
            ),
          ),
          Stack(children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              ),
            ),
            if (cart.items.isNotEmpty)
              Positioned(
                right: 6,
                top: 6,
                child: CircleAvatar(
                  radius: 8,
                  backgroundColor: Colors.redAccent,
                  child: Text("${cart.items.length}",
                      style: const TextStyle(fontSize: 10, color: Colors.white)),
                ),
              ),
          ]),
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
              }
            },
          ),
        ],
      ),

      // ===== Body =====
      body: Column(
        children: [
          // ===== Search + Filter =====
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: "🔍 Tìm theo tên hoặc SKU...",
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
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                          builder: (_) => FilterSheet(
                            minPrice: pp.minPrice,
                            maxPrice: pp.maxPrice,
                            sort: pp.sort,
                          ),
                        );
                        if (result != null) {
                          await pp.loadProducts(
                            minPrice: result.minPrice,
                            maxPrice: result.maxPrice,
                            sort: result.sort,
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear),
                      tooltip: 'Xóa tìm kiếm',
                      onPressed: () async {
                        _search.clear();
                        pp.clearFilters();
                        await pp.loadProducts();
                      },
                    ),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onSubmitted: (txt) =>
                  pp.loadProducts(query: txt.trim().isEmpty ? null : txt.trim()),
            ),
          ),

          // ===== Category + Refresh =====
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    isExpanded: true,
                    value: pp.categoryId ?? 0,
                    items: pp.categories
                        .map((c) => DropdownMenuItem<int>(
                      value: c.id,
                      child: Text(c.name),
                    ))
                        .toList(),
                    onChanged: (v) async => pp.loadProducts(categoryId: v),
                    decoration: InputDecoration(
                      labelText: "Danh mục",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text("Tải lại"),
                  onPressed: () => pp.loadProducts(),
                ),
              ],
            ),
          ),

          // ===== Grid sản phẩm =====
          Expanded(
            child: pp.loading
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: pp.products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemBuilder: (_, i) => _ProductTile(pp.products[i]),
            ),
          ),

          // ===== Pagination =====
          if (!pp.loading)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Text(
                    "Trang ${pp.page}/${pp.totalPages} • ${pp.total} sản phẩm",
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: pp.page > 1
                        ? () => pp.loadProducts(page: pp.page - 1)
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: pp.page < pp.totalPages
                        ? () => pp.loadProducts(page: pp.page + 1)
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),

      // ===== Bottom thanh toán =====
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(blurRadius: 4, color: Colors.black12, offset: Offset(0, -2))
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                "Tổng: ${cart.total.toStringAsFixed(0)} đ",
                style: theme.textTheme.titleMedium!
                    .copyWith(fontWeight: FontWeight.bold, color: primary),
              ),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.point_of_sale),
              label: const Text("Thanh toán"),
              onPressed: cart.items.isEmpty
                  ? null
                  : () async {
                final result = await showModalBottomSheet<CheckoutInput>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const CheckoutSheet(),
                );
                if (result == null) return;
                try {
                  final methodStr =
                  result.paymentMethod == PaymentMethodUI.transfer
                      ? "Transfer"
                      : "Cash";
                  final id = await context.read<CartProvider>().checkoutWithCustomer(
                    customerName: result.name,
                    customerPhone: result.phone,
                    printReceipt: result.printReceipt,
                    payNow: true,
                    paymentMethod: methodStr,
                  );
                  if (context.mounted) {
                    final label = result.paymentMethod ==
                        PaymentMethodUI.transfer
                        ? "CHUYỂN KHOẢN"
                        : "TIỀN MẶT";
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("✅ Đã lập hóa đơn #$id ($label)")));
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Lỗi thanh toán: $e")));
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
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: p.imageUrl == null
                ? const Center(child: Icon(Icons.image, size: 64, color: Colors.grey))
                : ClipRRect(
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(p.imageUrl!, fit: BoxFit.cover),
            ),
          ),
          ListTile(
            title: Text(p.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text(
              "${p.price.toStringAsFixed(0)} đ • Tồn: ${p.stock}",
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 8, bottom: 8),
            child: Row(
              children: [
                Expanded(
                    child: Text("SKU: ${p.sku}",
                        style:
                        const TextStyle(fontSize: 12, color: Colors.grey))),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                  onPressed: () {
                    context.read<CartProvider>().add(CartItem(product: p, quantity: 1));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("🛒 Đã thêm vào giỏ hàng"),
                        duration: Duration(milliseconds: 800),
                      ),
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

// ====== Filter Sheet ======
class _FilterResult {
  final double? minPrice, maxPrice;
  final String? sort;
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
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom, top: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Bộ lọc sản phẩm",
              style: Theme.of(context).textTheme.titleMedium),
          const Divider(),
          RangeSlider(
            min: 0,
            max: 1000000,
            divisions: 100,
            values: _range,
            labels: RangeLabels(
                "${_range.start.toInt()}đ", "${_range.end.toInt()}đ"),
            onChanged: (v) => setState(() => _range = v),
          ),
          DropdownButtonFormField<String>(
            value: _sort,
            items: const [
              DropdownMenuItem(value: 'name_asc', child: Text('Tên A→Z')),
              DropdownMenuItem(value: 'name_desc', child: Text('Tên Z→A')),
              DropdownMenuItem(value: 'price_asc', child: Text('Giá tăng dần')),
              DropdownMenuItem(value: 'price_desc', child: Text('Giá giảm dần')),
            ],
            onChanged: (v) => setState(() => _sort = v),
            decoration: const InputDecoration(labelText: 'Sắp xếp theo'),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              _FilterResult(
                minPrice: _range.start <= 0 ? null : _range.start,
                maxPrice: _range.end >= 1000000 ? null : _range.end,
                sort: _sort,
              ),
            ),
            child: const Text("Áp dụng"),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
