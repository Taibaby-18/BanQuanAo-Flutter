import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class CategoryAdminScreen extends StatefulWidget {
  const CategoryAdminScreen({super.key});

  @override
  State<CategoryAdminScreen> createState() => _CategoryAdminScreenState();
}

class _CategoryAdminScreenState extends State<CategoryAdminScreen> {
  List<dynamic> categories = [];
  bool loading = true;
  final nameCtrl = TextEditingController();

  Future<void> loadData() async {
    setState(() => loading = true);
    final client = context.read<AuthProvider>().client!;
    final data = await client.get('/api/categories');

    // ✅ Nếu API trả về Map chứa danh sách trong key "items" hoặc tương tự
    if (data is Map<String, dynamic> && data.containsKey('items')) {
      categories = data['items'] as List;
    } else if (data is List) {
      categories = data;
    } else {
      categories = [];
    }

    setState(() => loading = false);
  }


  Future<void> addCategory() async {
    final client = context.read<AuthProvider>().client!;
    if (nameCtrl.text.trim().isEmpty) return;
    await client.post('/api/categories', {'name': nameCtrl.text.trim()});
    nameCtrl.clear();
    await loadData();
  }

  Future<void> editCategory(Map<String, dynamic> cat) async {
    final controller = TextEditingController(text: cat['name']);
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Sửa danh mục"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "Tên danh mục"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          FilledButton(
            onPressed: () async {
              final client = context.read<AuthProvider>().client!;
              await client.put('/api/categories/${cat['id']}', {
                'id': cat['id'],
                'name': controller.text.trim(),
              });
              if (context.mounted) Navigator.pop(context);
              await loadData();
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  Future<void> deleteCategory(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Xóa danh mục?"),
        content: const Text("Bạn có chắc chắn muốn xóa danh mục này?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy")),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text("Xóa")),
        ],
      ),
    );
    if (ok != true) return;

    final client = context.read<AuthProvider>().client!;
    await client.delete('/api/categories/$id');
    await loadData();
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📁 Quản lý Danh mục"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: loadData),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: "Tên danh mục mới",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: addCategory,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...categories.map((c) => Card(
              child: ListTile(
                title: Text(c['name']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => editCategory(c),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => deleteCategory(c['id']),
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
