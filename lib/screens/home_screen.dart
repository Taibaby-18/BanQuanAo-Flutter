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
import '../widgets/checkout_sheet.dart'
    show CheckoutSheet, CheckoutInput, PaymentMethodUI;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _search = TextEditingController();

  // 🟢 Thêm các biến quản lý dữ liệu
  bool loading = true;
  List<dynamic> products = [];
  List<dynamic> categories = [];
  int? selectedCategoryId;

  // 🟢 HÀM TẢI DỮ LIỆU BAN ĐẦU
  Future<void> loadData() async {
    setState(() => loading = true);
    final client = context.read<AuthProvider>().client!;
    final prodData = await client.get('/api/products');
    final catData = await client.get('/api/categories');

    products = (prodData is Map && prodData['items'] != null)
        ? prodData['items']
        : (prodData is List ? prodData : []);
    categories = (catData is Map && catData['items'] != null)
        ? catData['items']
        : (catData is List ? catData : []);
    setState(() => loading = false);
  }

  // 🟢 HÀM LỌC THEO DANH MỤC
  Future<void> filterByCategory(int? id) async {
    setState(() => loading = true);
    final client = context.read<AuthProvider>().client!;
    final url =
    id == null || id == 0 ? '/api/products' : '/api/products?categoryId=$id';
    final data = await client.get(url);
    products = (data is Map && data['items'] != null)
        ? data['items']
        : (data is List ? data : []);
    selectedCategoryId = id;
    setState(() => loading = false);
  }

  // 🟢 HÀM TÌM KIẾM SẢN PHẨM
  Future<void> searchProducts(String query) async {
    setState(() => loading = true);
    final client = context.read<AuthProvider>().client!;
    final data = await client.get('/api/products?q=$query');
    products = (data is Map && data['items'] != null)
        ? data['items']
        : (data is List ? data : []);
    setState(() => loading = false);
  }

  @override
  void initState() {
    super.initState();
    loadData(); // ✅ gọi API khi mở trang
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    const primary = Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: primary,
        title: Row(
          children: [
            Image.asset('assets/images/hutech_logo.png', height: 28),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                "POS Bán hàng",
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
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
              icon:
              const Icon(Icons.shopping_cart_outlined, color: Colors.white),
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
                  child: Text(
                    "${cart.items.length}",
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
              ),
          ]),
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (_) => false);
              }
            },
          ),
        ],
      ),

      // ===== BODY =====
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ===== Search =====
            TextField(
              controller: _search,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: "🔍 Tìm theo tên hoặc SKU...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: 'Xóa tìm kiếm',
                  onPressed: () async {
                    _search.clear();
                    await loadData();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onSubmitted: (txt) async {
                if (txt.trim().isEmpty) {
                  await loadData();
                } else {
                  await searchProducts(txt.trim());
                }
              },
            ),
            const SizedBox(height: 12),

            // ===== Dropdown danh mục =====
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: selectedCategoryId ?? 0,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<int>(
                        value: 0,
                        child: Text("Tất cả danh mục"),
                      ),
                      ...categories.map<DropdownMenuItem<int>>(
                            (c) => DropdownMenuItem<int>(
                          value: c['id'],
                          child: Text(
                            c['name'],
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) async => await filterByCategory(v),
                    decoration: InputDecoration(
                      labelText: "Danh mục",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text("Tải lại"),
                  onPressed: loadData,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ===== DANH SÁCH SẢN PHẨM =====
            if (products.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    "Không có sản phẩm nào.",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              )
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: products
                    .map((p) =>
                    _productCard(context, Product.fromJson(p)))
                    .toList(),
              ),
          ],
        ),
      ),

      // ===== BOTTOM THANH TOÁN =====
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
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primary),
              ),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.point_of_sale),
              label: const Text("Thanh toán"),
              onPressed: cart.items.isEmpty
                  ? null
                  : () async {
                final result =
                await showModalBottomSheet<CheckoutInput>(
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
                  final id = await context
                      .read<CartProvider>()
                      .checkoutWithCustomer(
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
                        content:
                        Text("✅ Đã lập hóa đơn #$id ($label)")));
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

  // 🟢 CARD SẢN PHẨM
  Widget _productCard(BuildContext context, Product p) {
    const primary = Color(0xFF2563EB);
    const placeholderImage =
        "https://cdn-icons-png.flaticon.com/512/7874/7874609.png"; // ảnh mặc định

    // Nếu không có ảnh => dùng ảnh mặc định
    final imageUrl = (p.imageUrl == null || p.imageUrl!.isEmpty)
        ? placeholderImage
        : p.imageUrl!;

    return Container(
      width: MediaQuery.of(context).size.width / 2 - 24,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              p.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
              GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              "${p.price.toStringAsFixed(0)} đ • Tồn: ${p.stock}",
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    "SKU: ${p.sku}",
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: primary),
                onPressed: () {
                  context
                      .read<CartProvider>()
                      .add(CartItem(product: p, quantity: 1));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("🛒 Đã thêm vào giỏ hàng"),
                    duration: Duration(milliseconds: 700),
                  ));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

}
