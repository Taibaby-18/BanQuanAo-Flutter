import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ProductAdminScreen extends StatefulWidget {
  const ProductAdminScreen({super.key});

  @override
  State<ProductAdminScreen> createState() => _ProductAdminScreenState();
}

class _ProductAdminScreenState extends State<ProductAdminScreen> {
  List<dynamic> products = [];
  List<dynamic> categories = []; // ✅ danh sách danh mục
  bool loading = true;

  final _nameCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  int? selectedCategoryId; // ✅ id danh mục được chọn

  // ======================== LOAD DATA ========================
  Future<void> loadData() async {
    setState(() => loading = true);
    final client = context.read<AuthProvider>().client!;

    // Lấy sản phẩm
    final prodData = await client.get('/api/products');
    products = (prodData is Map<String, dynamic> && prodData.containsKey('items'))
        ? prodData['items']
        : (prodData is List ? prodData : []);

    // Lấy danh mục
    final catData = await client.get('/api/categories');
    categories = (catData is Map<String, dynamic> && catData.containsKey('items'))
        ? catData['items']
        : (catData is List ? catData : []);

    setState(() => loading = false);
  }

  // ======================== ADD ========================
  Future<void> addProduct() async {
    final client = context.read<AuthProvider>().client!;
    if (_nameCtrl.text.trim().isEmpty ||
        _skuCtrl.text.trim().isEmpty ||
        selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Vui lòng nhập đủ thông tin & chọn danh mục")),
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

    try {
      await client.post('/api/products', body);
      _nameCtrl.clear();
      _skuCtrl.clear();
      _priceCtrl.clear();
      _stockCtrl.clear();
      selectedCategoryId = null;
      await loadData();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Thêm sản phẩm thành công!")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Lỗi thêm sản phẩm: $e")),
        );
      }
    }
  }

  // ======================== DELETE ========================
  Future<void> deleteProduct(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Xóa sản phẩm?"),
        content: const Text("Bạn có chắc muốn xóa sản phẩm này?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy")),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text("Xóa")),
        ],
      ),
    );
    if (ok != true) return;

    final client = context.read<AuthProvider>().client!;
    await client.delete('/api/products/$id');
    await loadData();
  }

  // ======================== EDIT ========================
  Future<void> editProduct(Map<String, dynamic> p) async {
    final name = TextEditingController(text: p['name']);
    final price = TextEditingController(text: "${p['price']}");
    final stock = TextEditingController(text: "${p['stock']}");
    int categoryId = p['categoryId'] ?? 0;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sửa sản phẩm'),
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
                    .map<DropdownMenuItem<int>>(
                      (c) => DropdownMenuItem<int>(
                    value: c['id'],
                    child: Text(c['name']),
                  ),
                )
                    .toList(),
                onChanged: (v) => categoryId = v ?? categoryId,
                decoration: const InputDecoration(labelText: "Danh mục"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          FilledButton(
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
            child: const Text('Lưu'),
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

  // ======================== UI ========================
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("🛍️ Quản lý Sản phẩm"),
        actions: [
          IconButton(onPressed: loadData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text("Thêm sản phẩm mới", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Tên')),
            TextField(controller: _skuCtrl, decoration: const InputDecoration(labelText: 'SKU')),
            TextField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Giá'),
            ),
            TextField(
              controller: _stockCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Tồn kho'),
            ),
            const SizedBox(height: 8),

            // ✅ Dropdown chọn danh mục
            DropdownButtonFormField<int>(
              value: selectedCategoryId,
              items: categories
                  .map<DropdownMenuItem<int>>(
                    (cat) => DropdownMenuItem<int>(
                  value: cat['id'],
                  child: Text(cat['name']),
                ),
              )
                  .toList(),
              onChanged: (v) => setState(() => selectedCategoryId = v),
              decoration: const InputDecoration(labelText: "Danh mục"),
            ),

            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: addProduct,
              icon: const Icon(Icons.add),
              label: const Text('Thêm'),
            ),
            const Divider(height: 32),

            // Danh sách sản phẩm
            ...products.map((p) => Card(
              color: Colors.grey.shade50,
              child: ListTile(
                title: Text(p['name']),
                subtitle: Text("SKU: ${p['sku']} • Giá: ${p['price']} đ • Tồn: ${p['stock']}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => editProduct(p),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => deleteProduct(p['id']),
                    ),
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
