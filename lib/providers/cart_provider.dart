import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/dtos/order_create_dto.dart';
import '../services/api_client.dart';

class CartProvider with ChangeNotifier {
  ApiClient client;
  CartProvider({required this.client});

  void updateClient(ApiClient c) => client = c;

  final List<CartItem> _items = [];
  List<CartItem> get items => List.unmodifiable(_items);

  double get total => _items.fold<double>(0.0, (s, i) => s + i.lineTotal);

  // ===== Cart ops =====
  void add(CartItem item) {
    final idx = _items.indexWhere((e) => e.product.id == item.product.id);
    if (idx >= 0) {
      _items[idx].quantity += item.quantity;
    } else {
      _items.add(item);
    }
    debugPrint("[Cart] add product=${item.product.id} qty=${item.quantity} len=${_items.length} total=$total");
    notifyListeners();
  }

  void changeQty(int productId, int qty) {
    final i = _items.firstWhere(
          (e) => e.product.id == productId,
      orElse: () => throw Exception("Item not found"),
    );
    i.quantity = qty;
    if (i.quantity <= 0) {
      _items.removeWhere((e) => e.product.id == productId);
    }
    debugPrint("[Cart] changeQty id=$productId -> $qty total=$total");
    notifyListeners();
  }

  void remove(int productId) {
    _items.removeWhere((e) => e.product.id == productId);
    debugPrint("[Cart] remove id=$productId total=$total");
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  // ===== Checkout =====
  Future<int> checkoutWithCustomer({
    String? customerName,
    String? customerPhone,
    bool printReceipt = false,
    bool payNow = true,
    String paymentMethod = "Cash", // "Cash" | "Transfer"
  }) async {
    if (_items.isEmpty) throw Exception("Giỏ hàng trống");

    final dto = CreateOrderDto(
      items: _items
          .map((e) => CreateOrderItemDto(productId: e.product.id, qty: e.quantity))
          .toList(),
      customerName: (customerName?.trim().isEmpty ?? true) ? null : customerName!.trim(),
      customerPhone: (customerPhone?.trim().isEmpty ?? true) ? null : customerPhone!.trim(),
      printReceipt: printReceipt,
    );

    final res = await client.post("/api/Orders", dto.toJson());
    final orderId = (res['id'] as num).toInt();

    if (payNow) {
      await client.patchOrderStatus(orderId, "Paid", paymentMethod: paymentMethod);
    }

    clear();
    return orderId;
  }

  Future<int> checkout() => checkoutWithCustomer();
}
