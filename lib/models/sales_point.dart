class SalesPoint {
  final String label; // yyyy-MM-dd | Wxx/yyyy | mm/yyyy
  final int orders;
  final double revenue;

  SalesPoint({required this.label, required this.orders, required this.revenue});

  factory SalesPoint.fromJson(Map<String, dynamic> j) => SalesPoint(
    label: j['label'] as String,
    orders: j['orders'] as int,
    revenue: (j['revenue'] as num).toDouble(),
  );
}
