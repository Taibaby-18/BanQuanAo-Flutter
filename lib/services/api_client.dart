import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

/// API client đơn giản có gắn Bearer token.
/// Dùng kèm AuthService để tạo client sau khi đăng nhập.
class ApiClient {
  String? token;
  ApiClient({this.token});

  // Cho phép thay token mà không tạo instance mới.
  void setToken(String? t) => token = t;

  // ---------------- URL + Header ----------------
  Uri _u(String path, [Map<String, String?>? q]) {
    final base = AppConfig.apiBaseUrl; // ví dụ: http://10.0.2.2:5000
    final params = Map<String, String>.fromEntries(
      (q ?? const {}).entries.where((e) => e.value != null && e.value!.isNotEmpty)
          .map((e) => MapEntry(e.key, e.value!)),
    );
    return Uri.parse('$base$path').replace(queryParameters: params.isEmpty ? null : params);
  }

  Map<String, String> _headers({bool jsonBody = true}) => {
    if (jsonBody) 'Content-Type': 'application/json',
    if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  // ---------------- Low-level HTTP ----------------
  Future<http.Response> _wrap(Future<http.Response> f) async {
    final res = await f.timeout(const Duration(seconds: 20));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      // ném lỗi rõ ràng để UI hiển thị
      throw HttpException('HTTP ${res.statusCode}: ${res.body}');
    }
    return res;
  }

  dynamic _decode(http.Response r) {
    if (r.body.isEmpty) return null;
    // Decode UTF8 để tránh lỗi tiếng Việt
    final body = utf8.decode(r.bodyBytes);
    return jsonDecode(body);
  }

  Future<dynamic> get(String path, {Map<String, String?>? query}) async {
    final r = await _wrap(http.get(_u(path, query), headers: _headers(jsonBody: false)));
    return _decode(r);
  }

  Future<dynamic> post(String path, dynamic body) async {
    final r = await _wrap(http.post(_u(path), headers: _headers(), body: jsonEncode(body)));
    return _decode(r) ?? {};
  }
  Future<dynamic> put(String path, dynamic body) async {
    final r = await _wrap(http.put(
      _u(path),
      headers: _headers(),
      body: jsonEncode(body),
    ));
    return _decode(r) ?? {};
  }

  Future<dynamic> patch(String path, dynamic body) async {
    final r = await _wrap(http.patch(_u(path), headers: _headers(), body: jsonEncode(body)));
    return _decode(r) ?? {};
  }

  Future<dynamic> delete(String path) async {
    final r = await _wrap(http.delete(_u(path), headers: _headers(jsonBody: false)));
    return _decode(r);
  }

  // =========================================================
  //                      PRODUCTS / CATEGORIES
  // =========================================================
  Future<Map<String, dynamic>> getProducts({
    String? q,
    int? categoryId,
    double? minPrice,
    double? maxPrice,
    String? sort, // name_asc | name_desc | price_asc | price_desc
    int page = 1,
    int pageSize = 20,
  }) async {
    final data = await get('/api/Products', query: {
      'q': q,
      'categoryId': categoryId?.toString(),
      'minPrice': minPrice?.toStringAsFixed(0),
      'maxPrice': maxPrice?.toStringAsFixed(0),
      'sort': sort,
      'page': '$page',
      'pageSize': '$pageSize',
    });
    return (data as Map<String, dynamic>);
  }

  Future<List<dynamic>> getCategories() async {
    final data = await get('/api/Categories');
    return (data as List);
  }

  // =========================================================
  //                          ORDERS
  // =========================================================
  /// Lấy danh sách đơn của nhân viên hiện tại (đã đăng nhập).
  Future<List<dynamic>> getMyOrders() async {
    final data = await get('/api/Orders/my');
    return (data as List);
  }

  /// Chuyển enum string -> int theo backend hiện tại:
  /// OrderStatus { Pending=0, Paid=1, Cancelled=2, Returned=3 }
  int _statusToInt(String status) {
    switch (status) {
      case 'Paid':
        return 1;
      case 'Cancelled':
        return 2;
      case 'Returned':
        return 3;
      case 'Pending':
      default:
        return 0;
    }
  }

  /// PaymentMethod { Cash=0, ... } — chỉnh theo enum bạn đang dùng.
  int? _paymentToInt(String? method) {
    if (method == null) return null;
    switch (method) {
      case 'Cash':     return 0; // Tiền mặt
      case 'Transfer': return 1; // Chuyển khoản
    // case 'Card':  return 2; // (nếu sau này có)
      default:         return null;
    }
  }


  /// Cập nhật trạng thái đơn: "Paid" | "Cancelled" | "Returned"
  /// Backend hiện chưa bật JsonStringEnumConverter nên FE gửi **số**.
  Future<void> patchOrderStatus(int id, String status, {String? paymentMethod}) async {
    await patch('/api/Orders/$id/status', {
      'status': _statusToInt(status),
      'paymentMethod': _paymentToInt(paymentMethod),
    });
  }

  // =========================================================
  //                          REPORTS
  // =========================================================
  /// Doanh số cá nhân theo ngày|tuần|tháng
  Future<List<dynamic>> getMySales({
    String granularity = 'day',
    DateTime? from,
    DateTime? to,
  }) async {
    final data = await get('/api/Orders/my-sales', query: {
      'granularity': granularity,
      if (from != null) 'from': from.toIso8601String(),
      if (to != null) 'to': to.toIso8601String(),
    });
    return (data as List);
  }
}

/// Lỗi HTTP để show lên UI.
class HttpException implements Exception {
  final String message;
  HttpException(this.message);
  @override
  String toString() => 'HttpException: $message';
}
