import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
        title: const Text("✏️ Sửa danh mục"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "Tên danh mục",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy")),
          FilledButton.icon(
            onPressed: () async {
              final client = context.read<AuthProvider>().client!;
              await client.put('/api/categories/${cat['id']}', {
                'id': cat['id'],
                'name': controller.text.trim(),
              });
              if (context.mounted) Navigator.pop(context);
              await loadData();
            },
            icon: const Icon(Icons.save),
            label: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  Future<void> deleteCategory(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("🗑️ Xóa danh mục?"),
        content:
        const Text("Bạn có chắc chắn muốn xóa danh mục này không? Hành động không thể hoàn tác."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Hủy")),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete),
            label: const Text("Xóa"),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
          ),
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
    const primary = Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: primary,
        title: Row(
          children: [
            const Icon(Icons.category, color: Colors.white),
            const SizedBox(width: 8),
            const Text(
              "Quản lý Danh mục",
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: loadData,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ==== Form thêm danh mục ====
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: "Tên danh mục mới",
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.label_outline),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: addCategory,
                    icon: const Icon(Icons.add),
                    label: const Text("Thêm"),
                    style: FilledButton.styleFrom(
                      backgroundColor: primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ==== Danh sách danh mục ====
            Text(
              "📋 Danh sách danh mục",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),

            if (categories.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    "Không có danh mục nào.",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              )
            else
              ...categories.map((c) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    )
                  ],
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                    primary.withOpacity(0.1),
                    child: const Icon(Icons.category_outlined,
                        color: primary),
                  ),
                  title: Text(
                    c['name'],
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: "Sửa",
                        icon: const Icon(Icons.edit,
                            color: Colors.blueAccent),
                        onPressed: () => editCategory(c),
                      ),
                      IconButton(
                        tooltip: "Xóa",
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.redAccent),
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
