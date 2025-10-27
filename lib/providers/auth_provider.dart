import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final _auth = AuthService();

  String? _token;
  UserModel? _user;
  bool _ready = false;

  // ===== GETTER tiện dùng =====
  String? get token => _token;
  UserModel? get currentUser => _user;
  ApiClient? get client => _token == null ? null : ApiClient(token: _token);
  bool get isLoggedIn => _token != null;
  bool get ready => _ready;

  // ===== Khởi động app =====
  Future<void> bootstrap() async {
    _token = await _auth.getToken();
    final u = await _auth.getUser();
    _user = u == null ? null : UserModel.fromJson(u);
    _ready = true;
    notifyListeners();
  }

  // ===== Đăng nhập =====
  Future<void> login(String username, String password) async {
    final res = await _auth.login(username, password);
    _token = res['token'];
    _user = UserModel.fromJson(res['user']);
    _ready = true;
    notifyListeners();
  }

  // ===== Đăng xuất =====
  Future<void> logout() async {
    await _auth.logout();
    _token = null;
    _user = null;
    _ready = true;
    notifyListeners();
  }
}