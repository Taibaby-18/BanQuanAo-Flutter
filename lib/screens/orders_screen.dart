import 'package:flutter/material.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text("Đơn của tôi")),
      body: op.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
        padding: const EdgeInsets.all(12),
        itemBuilder: (_, i) => _OrderTile(op.myOrders[i]),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemCount: op.myOrders.length,
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final OrderModel o;
  const _OrderTile(this.o);

  Color _statusColor(BuildContext ctx) {
    switch (o.status) {
      case "Paid":
        return Colors.green;
      case "Cancelled":
        return Colors.red;
      case "Returned":
        return Colors.orange;
      default:
        return Theme.of(ctx).colorScheme.primary;
    }
  }

  /// pm có thể là int(0/1) hoặc string("Cash"/"Transfer") tuỳ backend
  String _pmText(dynamic pm) {
    if (pm == null) return "Không rõ";

    // int 0/1
    if (pm is int) return pm == 1 ? "Chuyển khoản" : "Tiền mặt";

    // string: "0"/"1" hoặc "cash"/"transfer"
    final s = pm.toString().trim().toLowerCase();
    if (s == "1" || s == "transfer") return "Chuyển khoản";
    if (s == "0" || s == "cash") return "Tiền mặt";

    // bất kỳ giá trị khác -> trả nguyên văn để debug
    return pm.toString();
  }


  @override
  Widget build(BuildContext context) {
    final op = context.read<OrderProvider>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text("#${o.id}", style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Chip(
                label: Text(o.status),
                backgroundColor: _statusColor(context).withOpacity(.15),
              ),
            ]),
            const SizedBox(height: 6),
            Text("Tổng: ${o.total.toStringAsFixed(0)} đ"),
            if (o.customerName != null || o.customerPhone != null)
              Text("KH: ${o.customerName ?? ''} ${o.customerPhone ?? ''}"),
            if (o.paidAt != null)
              Text(
                "Đã thanh toán: ${o.paidAt} • ${_pmText(o.paymentMethod)}",
              ),
            const SizedBox(height: 8),

            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: o.status == "Paid" ? () => op.returnOrder(o.id) : null,
                  child: const Text("Trả hàng"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
