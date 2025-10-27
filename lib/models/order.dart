class OrderModel {
  final int id;
  final String status;
  final double total;
  final String? customerName;
  final String? customerPhone;
  final DateTime? paidAt;
  final dynamic paymentMethod; // <-- để dynamic

  OrderModel({
    required this.id,
    required this.status,
    required this.total,
    this.customerName,
    this.customerPhone,
    this.paidAt,
    this.paymentMethod,
  });

  factory OrderModel.fromJson(Map<String, dynamic> j) => OrderModel(
    id: j['id'] as int,
    status: j['status'] is int
        ? (j['status'] == 1 ? 'Paid' : j['status'] == 2 ? 'Cancelled' : j['status'] == 3 ? 'Returned' : 'Pending')
        : (j['status']?.toString() ?? 'Pending'),
    total: (j['total'] as num).toDouble(),
    customerName: j['customerName'] as String?,
    customerPhone: j['customerPhone'] as String?,
    paidAt: j['paidAt'] != null ? DateTime.tryParse(j['paidAt'].toString()) : null,
    paymentMethod: j['paymentMethod'], // <-- giữ nguyên
  );
}
