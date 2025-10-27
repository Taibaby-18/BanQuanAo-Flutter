import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    try {
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Lỗi tải dữ liệu: $e")));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF2563EB);

    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: primary,
        title: Row(
          children: [
            Image.asset('assets/images/hutech_logo.png', height: 28),
            const SizedBox(width: 8),
            const Text(
              "Bảng điều khiển Admin",
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Quản lý sản phẩm",
            icon: const Icon(Icons.inventory, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProductAdminScreen()),
            ),
          ),
          IconButton(
            tooltip: "Quản lý danh mục",
            icon: const Icon(Icons.category, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CategoryAdminScreen()),
            ),
          ),
          IconButton(
            tooltip: "Quản lý khách hàng",
            icon: const Icon(Icons.people, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CustomerAdminScreen()),
            ),
          ),
          IconButton(
            tooltip: "Đăng xuất",
            icon: const Icon(Icons.logout, color: Colors.white),
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
            // ====== Tổng quan ======
            Text(
              "📈 Tổng quan hệ thống",
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            // ====== GỌI TRONG BODY ======
            _summarySection(context),
            const SizedBox(height: 24),

            const SizedBox(height: 24),

            // ====== Top nhân viên ======
            Text(
              "🏆 Top Nhân viên",
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (topEmployees != null && topEmployees!.isNotEmpty)
              ...topEmployees!.map((e) => Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo.withOpacity(0.1),
                    child: const Icon(Icons.person, color: Colors.indigo),
                  ),
                  title: Text(
                    e["employee"].toString(),
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    "Doanh thu: ${e["revenue"]} đ (${e["orders"]} đơn)",
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
              )),
            if (topEmployees == null || topEmployees!.isEmpty)
              const Text("Không có dữ liệu nhân viên."),

            const SizedBox(height: 24),

            // ====== Top sản phẩm ======
            Text(
              "🔥 Top sản phẩm bán chạy",
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (topProducts != null && topProducts!.isNotEmpty)
              ...topProducts!.map((e) => Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.purple.withOpacity(0.1),
                    child: const Icon(Icons.shopping_bag, color: Colors.purple),
                  ),
                  title: Text(
                    e["product"].toString(),
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    "Đã bán: ${e["qtySold"]} • Doanh thu: ${e["revenue"]} đ",
                    style: const TextStyle(color: Colors.black54),
                  ),
                ),
              )),
            if (topProducts == null || topProducts!.isEmpty)
              const Text("Không có dữ liệu sản phẩm."),
          ],
        ),
      ),
    );
  }

  // ====== CARD TỔNG QUAN ======
  // ====== PHẦN THẺ TỔNG QUAN ĐẸP MẮT ======
  Widget _summarySection(BuildContext context) {
    final items = [
      {
        'label': 'Đơn hàng',
        'value': summary?["totalOrders"]?.toString() ?? "0",
        'icon': Icons.receipt_long,
        'gradient': [const Color(0xFF2563EB), const Color(0xFF60A5FA)],
      },
      {
        'label': 'Doanh thu',
        'value': "${summary?["totalRevenue"] ?? 0} đ",
        'icon': Icons.monetization_on,
        'gradient': [const Color(0xFF16A34A), const Color(0xFF4ADE80)],
      },
      {
        'label': 'Khách hàng',
        'value': summary?["totalCustomers"]?.toString() ?? "0",
        'icon': Icons.people_alt,
        'gradient': [const Color(0xFFF59E0B), const Color(0xFFFACC15)],
      },
      {
        'label': 'Sản phẩm',
        'value': summary?["totalProducts"]?.toString() ?? "0",
        'icon': Icons.shopping_bag_outlined,
        'gradient': [const Color(0xFF9333EA), const Color(0xFFC084FC)],
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.25,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: item['gradient'] as List<Color>,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (item['gradient'] as List<Color>).first.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Icon(item['icon'] as IconData, color: Colors.white, size: 30),
              ),
              const Spacer(),
              Text(
                item['label'] as String,
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item['value'] as String,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
