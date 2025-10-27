// lib/models/dtos/order_create_dto.dart

class CreateOrderItemDto {
  final int productId;
  final int qty;

  CreateOrderItemDto({required this.productId, required this.qty});

  Map<String, dynamic> toJson() => {
    "productId": productId,
    "qty": qty,
  };
}

class CreateOrderDto {
  final List<CreateOrderItemDto> items;
  final String? customerName;
  final String? customerPhone;
  final bool printReceipt;

  CreateOrderDto({
    required this.items,
    this.customerName,
    this.customerPhone,
    required this.printReceipt,
  });

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{
      "items": items.map((e) => e.toJson()).toList(),
      "printReceipt": printReceipt,
    };
    if (customerName != null) m["customerName"] = customerName;
    if (customerPhone != null) m["customerPhone"] = customerPhone;
    return m;
  }
}
