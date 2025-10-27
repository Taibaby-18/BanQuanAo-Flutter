import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/report_provider.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        Provider.of<ReportProvider>(context, listen: false).load(granularity: 'day'));
  }

  @override
  Widget build(BuildContext context) {
    final rp = Provider.of<ReportProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Doanh số cá nhân"),
        actions: [
          TextButton(
            onPressed: () => rp.load(granularity: 'day'),
            child: Text("Ngày", style: TextStyle(color: rp.granularity=='day'?Theme.of(context).colorScheme.onPrimary: null)),
          ),
          TextButton(
            onPressed: () => rp.load(granularity: 'week'),
            child: Text("Tuần", style: TextStyle(color: rp.granularity=='week'?Theme.of(context).colorScheme.onPrimary: null)),
          ),
          TextButton(
            onPressed: () => rp.load(granularity: 'month'),
            child: Text("Tháng", style: TextStyle(color: rp.granularity=='month'?Theme.of(context).colorScheme.onPrimary: null)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: rp.loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(child: Text("Tổng đơn: ${rp.totalOrders}")),
                Expanded(child: Text("Doanh thu: ${rp.totalRevenue.toStringAsFixed(0)} đ",
                    textAlign: TextAlign.right)),
              ],
            ),
          ),
          const Divider(height: 0),
          Expanded(
            child: ListView.separated(
              itemCount: rp.points.length,
              separatorBuilder: (_, __) => const Divider(height: 0),
              itemBuilder: (_, i) {
                final p = rp.points[i];
                return ListTile(
                  title: Text(p.label),
                  subtitle: Text("${p.orders} đơn"),
                  trailing: Text("${p.revenue.toStringAsFixed(0)} đ"),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
