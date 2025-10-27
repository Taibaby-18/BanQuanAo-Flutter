import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final _base = "https://localhost:7034"; // URL API của bạn

  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse("$_base/api/Auth/login");
    final res = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (res.statusCode != 200) throw Exception("Sai tài khoản hoặc mật khẩu");
    final data = jsonDecode(res.body);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("token", data['token']);
    await prefs.setString("user", jsonEncode(data['user']));

    return data; // trả về {token, user}
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final u = prefs.getString("user");
    return u == null ? null : jsonDecode(u);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
    await prefs.remove("user");
  }
}
