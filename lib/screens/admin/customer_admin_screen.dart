import 'package:flutter/material.dart';
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

    List<dynamic> list;
    if (data is Map<String, dynamic> && data.containsKey('items')) {
      list = data['items'] as List;
    } else if (data is List) {
      list = data;
    } else {
      list = [];
    }

    setState(() {
      customers = list;
      loading = false;
    });
  }


  Future<void> addCustomer() async {
    final client = context.read<AuthProvider>().client!;
    if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) return;
    await client.post('/api/customers', {
      'name': nameCtrl.text.trim(),
      'phone': phoneCtrl.text.trim(),
    });
    nameCtrl.clear();
    phoneCtrl.clear();
    await loadData();
  }

  Future<void> editCustomer(Map<String, dynamic> c) async {
    final name = TextEditingController(text: c['name']);
    final phone = TextEditingController(text: c['phone']);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sửa khách hàng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Họ tên')),
            TextField(controller: phone, decoration: const InputDecoration(labelText: 'Số điện thoại')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          FilledButton(
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
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  Future<void> deleteCustomer(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa khách hàng?'),
        content: const Text('Bạn có chắc chắn muốn xóa khách hàng này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("👥 Quản lý Khách hàng"),
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
              decoration: const InputDecoration(labelText: 'Tên khách hàng'),
            ),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'Số điện thoại'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: addCustomer,
              icon: const Icon(Icons.add),
              label: const Text('Thêm khách hàng'),
            ),
            const Divider(height: 24),
            ...customers.map((c) => Card(
              child: ListTile(
                title: Text(c['name']),
                subtitle: Text('📞 ${c['phone']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => editCustomer(c),
                    ),
                    // IconButton(
                    //   icon: const Icon(Icons.delete, color: Colors.red),
                    //   onPressed: () => deleteCustomer(c['id']),
                    // ),
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
