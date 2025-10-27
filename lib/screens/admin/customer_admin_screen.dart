import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class CustomerAdminScreen extends StatefulWidget {
  const CustomerAdminScreen({super.key});

  @override
  State<CustomerAdminScreen> createState() => _CustomerAdminScreenState();
}

class _CustomerAdminScreenState extends State<CustomerAdminScreen> {
  List<dynamic> customers = [];
  bool loading = true;
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();

  Future<void> loadData() async {
    setState(() => loading = true);
    final client = context.read<AuthProvider>().client!;
    final data = await client.get('/api/customers');

    if (data is Map<String, dynamic> && data.containsKey('items')) {
      customers = data['items'] as List;
    } else if (data is List) {
      customers = data;
    } else {
      customers = [];
    }

    setState(() => loading = false);
  }

  Future<void> addCustomer() async {
    final client = context.read<AuthProvider>().client!;
    if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Vui lòng nhập đủ họ tên và số điện thoại")),
      );
      return;
    }

    await client.post('/api/customers', {
      'name': nameCtrl.text.trim(),
      'phone': phoneCtrl.text.trim(),
    });
    nameCtrl.clear();
    phoneCtrl.clear();
    await loadData();

    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("✅ Đã thêm khách hàng!")));
    }
  }

  Future<void> editCustomer(Map<String, dynamic> c) async {
    final name = TextEditingController(text: c['name']);
    final phone = TextEditingController(text: c['phone']);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("✏️ Sửa thông tin khách hàng"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Họ tên'),
            ),
            TextField(
              controller: phone,
              decoration: const InputDecoration(labelText: 'Số điện thoại'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          FilledButton.icon(
            onPressed: () async {
              final client = context.read<AuthProvider>().client!;
              await client.put('/api/customers/${c['id']}', {
                'id': c['id'],
                'name': name.text.trim(),
                'phone': phone.text.trim(),
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

  Future<void> deleteCustomer(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🗑️ Xóa khách hàng?'),
        content: const Text('Bạn có chắc chắn muốn xóa khách hàng này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final client = context.read<AuthProvider>().client!;
    await client.delete('/api/customers/$id');
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
            const Icon(Icons.people_alt, color: Colors.white),
            const SizedBox(width: 8),
            const Text("Quản lý khách hàng", style: TextStyle(color: Colors.white)),
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
            // ==== FORM THÊM KHÁCH HÀNG ====
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
                  Text("➕ Thêm khách hàng mới",
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: "Họ và tên",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: "Số điện thoại",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: addCustomer,
                      icon: const Icon(Icons.add),
                      label: const Text("Thêm"),
                      style: FilledButton.styleFrom(
                        backgroundColor: primary,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Text("📋 Danh sách khách hàng",
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600, fontSize: 18)),
            const SizedBox(height: 12),

            // ==== DANH SÁCH ====
            if (customers.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    "Chưa có khách hàng nào.",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ),
              )
            else
              ...customers.map((c) => Container(
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
                    child: const Icon(Icons.person, color: primary),
                  ),
                  title: Text(
                    c['name'],
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                  subtitle: Text("📞 ${c['phone']}",
                      style: GoogleFonts.inter(color: Colors.black54)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                          icon: const Icon(Icons.edit,
                              color: Colors.blueAccent),
                          onPressed: () => editCustomer(c)),
                      // IconButton(
                      //     icon: const Icon(Icons.delete_outline,
                      //         color: Colors.redAccent),
                      //     onPressed: () => deleteCustomer(c['id'])),
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
