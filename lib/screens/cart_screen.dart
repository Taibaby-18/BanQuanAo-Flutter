import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/checkout_sheet.dart'; // <-- thêm

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text("Giỏ hiện tại")),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              itemCount: cart.items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final it = cart.items[i];
                return ListTile(
                  title: Text(it.product.name),
                  subtitle: Text("${it.product.price.toStringAsFixed(0)} đ x ${it.quantity}"),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(icon: const Icon(Icons.remove), onPressed: () {
                      cart.changeQty(it.product.id, it.quantity - 1);
                    }),
                    IconButton(icon: const Icon(Icons.add), onPressed: () {
                      cart.changeQty(it.product.id, it.quantity + 1);
                    }),
                    IconButton(icon: const Icon(Icons.delete_outline), onPressed: () {
                      cart.remove(it.product.id);
                    }),
                  ]),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Text("Tổng: ${cart.total.toStringAsFixed(0)} đ",
                  style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              FilledButton.icon(
                icon: const Icon(Icons.point_of_sale),
                label: const Text("Thanh toán"),
                onPressed: cart.items.isEmpty ? null : () async {
                  final res = await showModalBottomSheet<CheckoutInput>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const CheckoutSheet(),
                  );
                  if (res == null) return;

                  try {
                    final id = await context.read<CartProvider>()
                        .checkoutWithCustomer(
                      customerName: res.name,
                      customerPhone: res.phone,
                      printReceipt: res.printReceipt,
                      paymentMethod: res.paymentMethod == PaymentMethodUI.transfer
                          ? "Transfer"
                          : "Cash",
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Đã lập hóa đơn #$id (đã thanh toán)")),
                      );
                      Navigator.pop(context); // đóng màn giỏ
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Thanh toán lỗi: $e")),
                      );
                    }
                  }
                },
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
