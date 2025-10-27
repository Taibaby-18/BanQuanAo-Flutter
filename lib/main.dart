import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'services/api_client.dart';
import 'providers/auth_provider.dart';
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'providers/report_provider.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
      useMaterial3: true,
      textTheme: GoogleFonts.interTextTheme(),
    );

    return MultiProvider(
      providers: [
        // Auth
        ChangeNotifierProvider(create: (_) => AuthProvider()..bootstrap()),

        // Products
        ChangeNotifierProxyProvider<AuthProvider, ProductProvider>(
          create: (_) => ProductProvider(client: ApiClient()),
          update: (_, auth, p) {
            p!.updateClient(ApiClient(token: auth.token));
            return p;
          },
        ),

        // Cart
        ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
          create: (_) => CartProvider(client: ApiClient()),
          update: (_, auth, c) {
            c!.updateClient(ApiClient(token: auth.token));
            return c;
          },
        ),

        // Orders
        ChangeNotifierProxyProvider<AuthProvider, OrderProvider>(
          create: (_) => OrderProvider(client: ApiClient()),
          update: (_, auth, op) {
            op!.updateClient(ApiClient(token: auth.token));
            return op;
          },
        ),

        // Reports
        ChangeNotifierProxyProvider<AuthProvider, ReportProvider>(
          create: (_) => ReportProvider(client: ApiClient()),
          update: (_, auth, rp) {
            rp!.updateClient(ApiClient(token: auth.token));
            return rp;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Shop POS',
        debugShowCheckedModeBanner: false,
        theme: theme,

        // ✅ Routes cho Navigator.pushNamed(...)
        routes: {
          '/login': (_) => const LoginScreen(),
          '/home': (_) => const HomeScreen(),
          '/admin': (_) => const AdminDashboardScreen(),
        },

        // ✅ Màn hình khởi động
        home: const _Root(),
      ),
    );
  }
}

class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final auth = context.read<AuthProvider>();
    await auth.bootstrap();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (_loading || !auth.ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!auth.isLoggedIn) {
      return const LoginScreen();
    }

    final role = auth.currentUser?.role ?? 'Staff';
    if (role == 'Admin') {
      return const AdminDashboardScreen();
    } else {
      return const HomeScreen();
    }
  }
}
