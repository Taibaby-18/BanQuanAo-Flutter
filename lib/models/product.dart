class Product {
  final int id;
  final String sku;
  final String name;
  final double price;
  final String? imageUrl;
  final int stock;
  final int categoryId;
  final String? categoryName;

  Product({
    required this.id,
    required this.sku,
    required this.name,
    required this.price,
    required this.stock,
    required this.categoryId,
    this.imageUrl,
    this.categoryName,
  });

  factory Product.fromJson(Map<String, dynamic> j) => Product(
    id: j['id'] as int,
    sku: j['sku'] as String,
    name: j['name'] as String,
    price: (j['price'] as num).toDouble(),
    imageUrl: j['imageUrl'] as String?,
    stock: j['stock'] as int,
    categoryId: j['categoryId'] as int,
    categoryName: j['Category'] as String?, // server trả "Category"
  );
}
