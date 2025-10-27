import 'package:flutter/foundation.dart';
import '../services/api_client.dart';
import '../models/order.dart';

class OrderProvider with ChangeNotifier {
  ApiClient client;
  OrderProvider({required this.client});
  void updateClient(ApiClient c) => client = c;

  List<OrderModel> myOrders = [];
  bool loading = false;

  Future<void> loadMyOrders() async {
    loading = true; notifyListeners();
    final list = await client.getMyOrders();
    myOrders = list.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
    loading = false; notifyListeners();
  }

  /// Thanh toán TIỀN MẶT (COD)
  Future<void> payCash(int orderId) async {
    await client.patchOrderStatus(orderId, "Paid", paymentMethod: "Cash");
    await loadMyOrders();
  }

  /// 🔹 Thanh toán CHUYỂN KHOẢN
  Future<void> payTransfer(int orderId) async {
    await client.patchOrderStatus(orderId, "Paid", paymentMethod: "Transfer");
    await loadMyOrders();
  }

  Future<void> cancel(int orderId) async {
    await client.patchOrderStatus(orderId, "Cancelled");
    await loadMyOrders();
  }

  Future<void> returnOrder(int orderId) async {
    await client.patchOrderStatus(orderId, "Returned");
    await loadMyOrders();
  }
}
