import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'admin/admin_dashboard_screen.dart'; // 👈 thêm import mới

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _u = TextEditingController();
  final _p = TextEditingController();
  bool _loading = false;
  String? _err;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 360,
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Đăng nhập hệ thống",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _u,
                    decoration: const InputDecoration(
                      labelText: "Tên đăng nhập",
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _p,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "Mật khẩu",
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_err != null)
                    Text(_err!, style: const TextStyle(color: Colors.red)),

                  const SizedBox(height: 16),

                  FilledButton.icon(
                    icon: const Icon(Icons.login),
                    label: _loading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text("Đăng nhập"),
                    onPressed: _loading
                        ? null
                        : () async {
                      setState(() {
                        _loading = true;
                        _err = null;
                      });
                      try {
                        await context
                            .read<AuthProvider>()
                            .login(_u.text.trim(), _p.text);

                        if (!context.mounted) return;

                        final user =
                            context.read<AuthProvider>().currentUser;
                        final role = user?.role ?? "Staff";

                        // 🧠 Điều hướng theo quyền
                        if (role == "Admin") {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                              const AdminDashboardScreen(),
                            ),
                          );
                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HomeScreen(),
                            ),
                          );
                        }
                      } catch (e) {
                        setState(() => _err = e.toString());
                      } finally {
                        setState(() => _loading = false);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
