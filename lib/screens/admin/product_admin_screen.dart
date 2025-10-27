import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ProductAdminScreen extends StatefulWidget {
  const ProductAdminScreen({super.key});

  @override
  State<ProductAdminScreen> createState() => _ProductAdminScreenState();
}

class _ProductAdminScreenState extends State<ProductAdminScreen> {
  List<dynamic> products = [];
  List<dynamic> categories = [];
  bool loading = true;

  final _nameCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  int? selectedCategoryId;

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

  Future<void> addProduct() async {
    final client = context.read<AuthProvider>().client!;
    if (_nameCtrl.text.trim().isEmpty ||
        _skuCtrl.text.trim().isEmpty ||
        selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Vui lòng nhập đầy đủ thông tin!")),
      );
      return;
    }

    final body = {
      "name": _nameCtrl.text.trim(),
      "sku": _skuCtrl.text.trim(),
      "price": double.tryParse(_priceCtrl.text) ?? 0,
      "stock": int.tryParse(_stockCtrl.text) ?? 0,
      "categoryId": selectedCategoryId,
    };

    await client.post('/api/products', body);
    _nameCtrl.clear();
    _skuCtrl.clear();
    _priceCtrl.clear();
    _stockCtrl.clear();
    selectedCategoryId = null;
    await loadData();

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("✅ Đã thêm sản phẩm!")));
    }
  }

  Future<void> deleteProduct(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("🗑️ Xóa sản phẩm?"),
        content: const Text("Bạn có chắc muốn xóa sản phẩm này không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy")),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Xóa"),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final client = context.read<AuthProvider>().client!;
    await client.delete('/api/products/$id');
    await loadData();
  }

  Future<void> editProduct(Map<String, dynamic> p) async {
    final name = TextEditingController(text: p['name']);
    final price = TextEditingController(text: "${p['price']}");
    final stock = TextEditingController(text: "${p['stock']}");
    int categoryId = p['categoryId'] ?? 0;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("✏️ Sửa sản phẩm"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Tên')),
              TextField(controller: price, decoration: const InputDecoration(labelText: 'Giá')),
              TextField(controller: stock, decoration: const InputDecoration(labelText: 'Tồn kho')),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: categoryId,
                items: categories
                    .map<DropdownMenuItem<int>>((c) => DropdownMenuItem<int>(
                  value: c['id'],
                  child: Text(c['name']),
                ))
                    .toList(),
                onChanged: (v) => categoryId = v ?? categoryId,
                decoration: const InputDecoration(labelText: "Danh mục"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          FilledButton.icon(
            onPressed: () async {
              final client = context.read<AuthProvider>().client!;
              await client.put('/api/products/${p['id']}', {
                "id": p['id'],
                "name": name.text.trim(),
                "price": double.tryParse(price.text) ?? 0,
                "stock": int.tryParse(stock.text) ?? 0,
                "sku": p['sku'],
                "categoryId": categoryId,
              });
              if (context.mounted) Navigator.pop(context);
              await loadData();
            },
            icon: const Icon(Icons.save),
            label: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: primary,
        title: Row(
          children: [
            const Icon(Icons.shopping_bag, color: Colors.white),
            const SizedBox(width: 8),
            const Text("Quản lý sản phẩm", style: TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: loadData),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ==== Form thêm sản phẩm ====
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("➕ Thêm sản phẩm mới",
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 12),
                  TextField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Tên sản phẩm', border: OutlineInputBorder())),
                  const SizedBox(height: 8),
                  TextField(
                      controller: _skuCtrl,
                      decoration: const InputDecoration(
                          labelText: 'SKU', border: OutlineInputBorder())),
                  const SizedBox(height: 8),
                  TextField(
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Giá', border: OutlineInputBorder())),
                  const SizedBox(height: 8),
                  TextField(
                      controller: _stockCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Tồn kho', border: OutlineInputBorder())),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: selectedCategoryId,
                    items: categories
                        .map<DropdownMenuItem<int>>(
                            (cat) => DropdownMenuItem<int>(
                          value: cat['id'],
                          child: Text(cat['name']),
                        ))
                        .toList(),
                    onChanged: (v) => setState(() => selectedCategoryId = v),
                    decoration: const InputDecoration(
                        labelText: "Danh mục", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: addProduct,
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm'),
                      style: FilledButton.styleFrom(
                        backgroundColor: primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text("📋 Danh sách sản phẩm",
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, fontSize: 18)),
            const SizedBox(height: 12),

            if (products.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text("Không có sản phẩm nào.",
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                ),
              )
            else
              ...products.map((p) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 3)),
                  ],
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: primary.withOpacity(0.1),
                    child: const Icon(Icons.inventory_2_outlined,
                        color: primary),
                  ),
                  title: Text(
                    p['name'],
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  subtitle: Text(
                    "SKU: ${p['sku']} • Giá: ${p['price']} đ • Tồn: ${p['stock']}",
                    style: GoogleFonts.inter(color: Colors.black54),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                          icon: const Icon(Icons.edit,
                              color: Colors.blueAccent),
                          onPressed: () => editProduct(p)),
                      IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.redAccent),
                          onPressed: () => deleteProduct(p['id'])),
                    ],
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }
}
