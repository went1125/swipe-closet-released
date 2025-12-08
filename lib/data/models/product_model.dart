class Product {
  final String id;
  final String name;
  final double price;
  final List<String> images; // ★ 改成 List<String>
  final String description;  // ★ 新增描述
  final String deepLink;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.images,
    required this.description,
    required this.deepLink,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // 處理圖片：後端可能給單張 imageUrl 或多張 images
    List<String> imgList = [];
    if (json['images'] != null) {
      imgList = List<String>.from(json['images']);
    } else if (json['imageUrl'] != null) {
      imgList = [json['imageUrl']];
    } else {
      imgList = ['https://via.placeholder.com/400']; // 防呆
    }

    return Product(
      id: json['id'].toString(),
      name: json['name'] ?? '未知商品',
      price: (json['price'] ?? 0).toDouble(),
      images: imgList,
      description: json['description'] ?? '暫無商品說明，請查看詳細資訊。', // 預設文案
      deepLink: json['deepLink'] ?? '',
    );
  }
}