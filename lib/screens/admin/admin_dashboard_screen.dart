import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_client.dart';
import '../../providers/auth_provider.dart';
import 'product_admin_screen.dart';
import 'category_admin_screen.dart';
import 'customer_admin_screen.dart';
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? summary;
  List<dynamic>? topEmployees;
  List<dynamic>? topProducts;
  bool loading = true;

  Future<void> loadData() async {
    final client = context.read<AuthProvider>().client!;
    final sum = await client.get("/api/adminreports/summary");
    final emps = await client.get("/api/adminreports/top-employees?limit=5");
    final prods = await client.get("/api/adminreports/top-products?limit=5");

    setState(() {
      summary = sum;
      topEmployees = emps;
      topProducts = prods;
      loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("📊 Bảng điều khiển Admin"),
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory),
            tooltip: "Quản lý sản phẩm",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProductAdminScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.category),
            tooltip: "Quản lý Danh mục",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CategoryAdminScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: "Quản lý khách hàng",
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CustomerAdminScreen()),
            ),
          ),
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
      body: RefreshIndicator(
        onRefresh: loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ===== Tổng quan =====
            Text("Tổng quan", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _summaryCard("Đơn hàng", summary?["totalOrders"].toString()),
                _summaryCard("Doanh thu", "${summary?["totalRevenue"]} đ"),
                _summaryCard("Khách hàng", summary?["totalCustomers"].toString()),
                _summaryCard("Sản phẩm", summary?["totalProducts"].toString()),
              ],
            ),
            const SizedBox(height: 20),

            // ===== Top nhân viên =====
            Text("🏆 Top Nhân Viên", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...?topEmployees?.map((e) => ListTile(
              leading: const Icon(Icons.person),
              title: Text(e["employee"].toString()),
              subtitle: Text("Doanh thu: ${e["revenue"]} đ (${e["orders"]} đơn)"),
            )),

            const SizedBox(height: 20),

            // ===== Top sản phẩm =====
            Text("🔥 Top Sản Phẩm", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...?topProducts?.map((e) => ListTile(
              leading: const Icon(Icons.shopping_bag),
              title: Text(e["product"].toString()),
              subtitle: Text("Đã bán: ${e["qtySold"]} • Doanh thu: ${e["revenue"]} đ"),
            )),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String label, String? value) {
    return Container(
      width: MediaQuery.of(context).size.width / 2 - 24,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(value ?? "-", style: const TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}
