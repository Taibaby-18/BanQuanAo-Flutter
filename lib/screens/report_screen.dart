import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().load(granularity: 'day');
    });
  }

  @override
  Widget build(BuildContext context) {
    final rp = context.watch<ReportProvider>();
    const primary = Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: primary,
        title: Row(
          children: [
            // Image.asset('assets/images/hutech_logo.png', height: 28),
            const SizedBox(width: 8),
            const Text(
              "Báo cáo",
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          _granularityButton(context, rp, 'day', 'Ngày'),
          _granularityButton(context, rp, 'week', 'Tuần'),
          _granularityButton(context, rp, 'month', 'Tháng'),
          const SizedBox(width: 8),
        ],
      ),
      body: rp.loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () async => rp.load(granularity: rp.granularity),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ====== Tổng quan ======
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  )
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    "Tổng quan doanh số",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _summaryTile(
                        "Tổng đơn",
                        rp.totalOrders.toString(),
                        Icons.receipt_long,
                        Colors.indigo,
                      ),
                      _summaryTile(
                        "Doanh thu",
                        "${rp.totalRevenue.toStringAsFixed(0)} đ",
                        Icons.monetization_on,
                        Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ====== Biểu đồ doanh thu ======
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  )
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Biểu đồ doanh thu (${_granularityLabel(rp.granularity)})",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: BarChart(
                      BarChartData(
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(show: false),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 24,
                              getTitlesWidget: (v, _) {
                                final index = v.toInt();
                                if (index < 0 || index >= rp.points.length) {
                                  return const SizedBox.shrink();
                                }
                                return Text(
                                  rp.points[index].label,
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          leftTitles:
                          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles:
                          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles:
                          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        barGroups: rp.points
                            .asMap()
                            .entries
                            .map(
                              (e) => BarChartGroupData(
                            x: e.key,
                            barRods: [
                              BarChartRodData(
                                toY: e.value.revenue,
                                color: primary,
                                width: 14,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                        )
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ====== Danh sách chi tiết ======
            Text(
              "Chi tiết theo ${_granularityLabel(rp.granularity)}",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            ...rp.points.map(
                  (p) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(p.label),
                  subtitle: Text("${p.orders} đơn hàng"),
                  trailing: Text(
                    "${p.revenue.toStringAsFixed(0)} đ",
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== Helper Widgets =====
  Widget _granularityButton(
      BuildContext context, ReportProvider rp, String value, String label) {
    final bool active = rp.granularity == value;
    return TextButton(
      onPressed: () => rp.load(granularity: value),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : Colors.white70,
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _summaryTile(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: GoogleFonts.inter(color: Colors.grey[700]),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  String _granularityLabel(String g) {
    switch (g) {
      case 'day':
        return 'Ngày';
      case 'week':
        return 'Tuần';
      case 'month':
        return 'Tháng';
      default:
        return '';
    }
  }
}