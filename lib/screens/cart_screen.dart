import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/checkout_sheet.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final theme = Theme.of(context);
    const primary = Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: primary,
        title: Row(
          children: [
            Image.asset('assets/images/hutech_logo.png', height: 28),
            const SizedBox(width: 8),
            const Text("Giỏ hàng HUTECH", style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
      body: Column(
        children: [
          // ===== Danh sách sản phẩm trong giỏ =====
          Expanded(
            child: cart.items.isEmpty
                ? const Center(
              child: Text("🛒 Giỏ hàng trống",
                  style: TextStyle(fontSize: 18, color: Colors.grey)),
            )
                : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: cart.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final it = cart.items[i];
                final product = it.product;

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                  child: ListTile(
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: product.imageUrl == null
                          ? Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, color: Colors.grey),
                      )
                          : Image.network(
                        product.imageUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(
                      product.name,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    subtitle: Text(
                      "${product.price.toStringAsFixed(0)} đ x ${it.quantity}",
                      style: GoogleFonts.inter(color: Colors.grey[700]),
                    ),
                    trailing: SizedBox(
                      width: 130,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _qtyButton(
                            icon: Icons.remove,
                            color: Colors.orange,
                            onTap: () => cart.changeQty(product.id, it.quantity - 1),
                          ),
                          Padding(
                            padding:
                            const EdgeInsets.symmetric(horizontal: 6.0),
                            child: Text("${it.quantity}",
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold)),
                          ),
                          _qtyButton(
                            icon: Icons.add,
                            color: Colors.green,
                            onTap: () => cart.changeQty(product.id, it.quantity + 1),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.redAccent),
                            tooltip: "Xóa",
                            onPressed: () => cart.remove(product.id),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ===== Tổng tiền + nút thanh toán =====
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, -2))
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "Tổng cộng:",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                Text(
                  "${cart.total.toStringAsFixed(0)} đ",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: primary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.point_of_sale),
                label: const Text("Thanh toán ngay"),
                onPressed: cart.items.isEmpty
                    ? null
                    : () async {
                  final res = await showModalBottomSheet<CheckoutInput>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20))),
                    builder: (_) => const CheckoutSheet(),
                  );
                  if (res == null) return;

                  try {
                    final id = await context
                        .read<CartProvider>()
                        .checkoutWithCustomer(
                      customerName: res.name,
                      customerPhone: res.phone,
                      printReceipt: res.printReceipt,
                      paymentMethod:
                      res.paymentMethod == PaymentMethodUI.transfer
                          ? "Transfer"
                          : "Cash",
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                "✅ Đã lập hóa đơn #$id (đã thanh toán thành công)")),
                      );
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Lỗi thanh toán: $e")),
                      );
                    }
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ====== Nút tăng giảm số lượng ======
  Widget _qtyButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
