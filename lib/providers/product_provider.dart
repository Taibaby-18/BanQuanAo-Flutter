import 'package:flutter/foundation.dart' show ChangeNotifier;
import '../models/product.dart';
import '../models/category.dart';
import '../services/api_client.dart';

class ProductProvider with ChangeNotifier {
  ApiClient client;
  ProductProvider({required this.client});

  // data
  List<Product> products = [];
  List<Category> categories = [Category(id: 0, name: 'Tất cả')];

  // filters & paging
  String? keyword;
  int? categoryId;           // null => tất cả
  double? minPrice, maxPrice;
  String? sort;              // name_asc | name_desc | price_asc | price_desc
  int page = 1, pageSize = 20, total = 0;

  bool loading = false;

  void updateClient(ApiClient c) { client = c; }

  Future<void> loadCategories() async {
    try {
      final list = await client.getCategories();
      categories = [Category(id: 0, name: 'Tất cả')] +
          list.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      categories = [Category(id: 0, name: 'Tất cả')];
    }
    notifyListeners();
  }

  Future<void> loadProducts({
    String? query,
    int? categoryId,
    double? minPrice,
    double? maxPrice,
    String? sort,
    int? page,
  }) async {
    loading = true; notifyListeners();

    if (query != null) keyword = query;
    if (categoryId != null) this.categoryId = (categoryId == 0) ? null : categoryId;
    if (minPrice != null) this.minPrice = minPrice;
    if (maxPrice != null) this.maxPrice = maxPrice;
    if (sort != null) this.sort = sort;
    if (page != null) this.page = page;

    final res = await client.getProducts(
      q: keyword,
      categoryId: this.categoryId,
      minPrice: this.minPrice,
      maxPrice: this.maxPrice,
      sort: this.sort ?? 'name_asc',
      page: this.page,
      pageSize: pageSize,
    );

    total    = res['total'] as int;
    this.page     = res['page'] as int;
    pageSize = res['pageSize'] as int;

    final List items = res['items'] as List;
    products = items.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();

    loading = false; notifyListeners();
  }

  void clearFilters() {
    keyword = null; categoryId = null; minPrice = null; maxPrice = null; sort = null; page = 1;
    notifyListeners();
  }

  int get totalPages {
    if (pageSize <= 0) return 1;
    // làm tròn lên: (total + pageSize - 1) / pageSize
    final t = (total + pageSize - 1) ~/ pageSize;
    return t < 1 ? 1 : t;
  }

}
