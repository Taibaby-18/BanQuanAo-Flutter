// lib/widgets/checkout_sheet.dart
import 'package:flutter/material.dart';

/// Phương thức thanh toán hiển thị trên UI
enum PaymentMethodUI { cash, transfer }

/// Kết quả trả về từ sheet
class CheckoutInput {
  final String? name;
  final String? phone;
  final bool printReceipt;
  final PaymentMethodUI paymentMethod;

  CheckoutInput({
    this.name,
    this.phone,
    required this.printReceipt,
    required this.paymentMethod,
  });
}

class CheckoutSheet extends StatefulWidget {
  const CheckoutSheet({super.key});

  @override
  State<CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<CheckoutSheet> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _print = false;
  PaymentMethodUI _method = PaymentMethodUI.cash;

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Material(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Thông tin khách hàng", style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: "Tên khách (tuỳ chọn)"),
                ),
                TextFormField(
                  controller: _phone,
                  decoration: const InputDecoration(labelText: "SĐT (tuỳ chọn)"),
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    final x = v?.trim() ?? "";
                    if (x.isEmpty) return null;
                    if (x.length < 8) return "SĐT không hợp lệ";
                    return null;
                  },
                ),

                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Phương thức thanh toán", style: Theme.of(context).textTheme.titleSmall),
                ),
                RadioListTile<PaymentMethodUI>(
                  value: PaymentMethodUI.cash,
                  groupValue: _method,
                  onChanged: (v) => setState(() => _method = v!),
                  title: const Text("Tiền mặt (Cash)"),
                  dense: true,
                ),
                RadioListTile<PaymentMethodUI>(
                  value: PaymentMethodUI.transfer,
                  groupValue: _method,
                  onChanged: (v) => setState(() => _method = v!),
                  title: const Text("Chuyển khoản (Transfer)"),
                  dense: true,
                ),

                const SizedBox(height: 8),
                CheckboxListTile(
                  value: _print,
                  onChanged: (v) => setState(() => _print = v ?? false),
                  title: const Text("In hóa đơn sau khi thanh toán"),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),

                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Huỷ"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          if (!_formKey.currentState!.validate()) return;
                          Navigator.pop(
                            context,
                            CheckoutInput(
                              name: _name.text.trim().isEmpty ? null : _name.text.trim(),
                              phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
                              printReceipt: _print,
                              paymentMethod: _method,
                            ),
                          );
                        },
                        child: const Text("Xác nhận"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
