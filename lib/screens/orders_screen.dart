import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../models/order.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
          (_) => context.read<OrderProvider>().loadMyOrders(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final op = context.watch<OrderProvider>();
    const primary = Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: primary,
        title: Row(
          children: [
            Image.asset('assets/images/hutech_logo.png', height: 28),
            const SizedBox(width: 8),
            const Text("Đơn hàng của tôi", style: TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => op.loadMyOrders(),
          ),
        ],
      ),
      body: op.loading
          ? const Center(child: CircularProgressIndicator())
          : op.myOrders.isEmpty
          ? const Center(
        child: Text(
          "📦 Chưa có đơn hàng nào",
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      )
          : RefreshIndicator(
        onRefresh: () async => op.loadMyOrders(),
        child: ListView.separated(
          padding: const EdgeInsets.all(12),
          itemBuilder: (_, i) => _OrderTile(o: op.myOrders[i]),
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemCount: op.myOrders.length,
        ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final OrderModel o;
  const _OrderTile({required this.o});

  Color _statusColor() {
    switch (o.status.toLowerCase()) {
      case "paid":
        return Colors.green;
      case "cancelled":
        return Colors.redAccent;
      case "returned":
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _statusIcon() {
    switch (o.status.toLowerCase()) {
      case "paid":
        return Icons.check_circle;
      case "cancelled":
        return Icons.cancel;
      case "returned":
        return Icons.assignment_return;
      default:
        return Icons.pending_actions;
    }
  }

  String _pmText(dynamic pm) {
    if (pm == null) return "Không rõ";
    if (pm is int) return pm == 1 ? "Chuyển khoản" : "Tiền mặt";
    final s = pm.toString().trim().toLowerCase();
    if (s == "1" || s == "transfer") return "Chuyển khoản";
    if (s == "0" || s == "cash") return "Tiền mặt";
    return pm.toString();
  }

  @override
  Widget build(BuildContext context) {
    final op = context.read<OrderProvider>();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== Header đơn =====
          Row(
            children: [
              Icon(_statusIcon(), color: _statusColor()),
              const SizedBox(width: 8),
              Text(
                "Đơn #${o.id}",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Chip(
                label: Text(
                  o.status,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _statusColor(),
                  ),
                ),
                backgroundColor: _statusColor().withOpacity(0.1),
              ),
            ],
          ),

          const SizedBox(height: 8),
          Divider(color: Colors.grey[300]),

          // ===== Thông tin đơn =====
          const SizedBox(height: 6),
          _infoRow("Tổng tiền:", "${o.total.toStringAsFixed(0)} đ"),
          if (o.customerName != null && o.customerName!.isNotEmpty)
            _infoRow("Khách hàng:", o.customerName!),
          if (o.customerPhone != null && o.customerPhone!.isNotEmpty)
            _infoRow("Số điện thoại:", o.customerPhone!),
          if (o.paidAt != null)
            _infoRow(
              "Thanh toán:",
              "${o.paidAt} • ${_pmText(o.paymentMethod)}",
            ),

          const SizedBox(height: 12),

          // ===== Nút hành động =====
          FilledButton.icon(
            icon: const Icon(Icons.assignment_return),
            label: const Text("Trả hàng"),
            onPressed: o.status.toLowerCase() == "paid"
                ? () => op.returnOrder(o.id)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
