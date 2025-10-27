import 'package:flutter/foundation.dart';
import '../services/api_client.dart';
import '../models/sales_point.dart';

class ReportProvider with ChangeNotifier {
  ApiClient client;
  ReportProvider({required this.client});

  String granularity = 'day'; // day|week|month
  List<SalesPoint> points = [];
  bool loading = false;

  double get totalRevenue => points.fold(0.0, (s, x) => s + x.revenue);
  int get totalOrders => points.fold(0, (s, x) => s + x.orders);

  void updateClient(ApiClient c) => client = c;

  Future<void> load({String? granularity, DateTime? from, DateTime? to}) async {
    if (granularity != null) this.granularity = granularity;
    loading = true; notifyListeners();
    final list = await client.getMySales(
      granularity: this.granularity,
      from: from, to: to,
    );
    points = list.map((e) => SalesPoint.fromJson(e as Map<String, dynamic>)).toList();
    loading = false; notifyListeners();
  }
}
