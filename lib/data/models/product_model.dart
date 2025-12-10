// lib/data/models/product_model.dart

class Product {
  final String id;
  final String name;
  final double price;
  final List<String> images;
  final String description;
  final String deepLink;
  final List<String> categories; // 演算法用

  // Helper: 取得第一張圖當縮圖
  String get imageUrl => images.isNotEmpty ? images.first : 'https://via.placeholder.com/400';

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.images,
    required this.description,
    required this.deepLink,
    this.categories = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // --- 1. 圖片解析防呆 (核心修正點) ---
    List<String> safeImages = [];
    try {
      if (json['images'] != null && json['images'] is List) {
        final list = json['images'] as List;
        if (list.isNotEmpty) {
          // 情況 A: 聯盟網格式 [{"url": "..."}]
          if (list.first is Map && (list.first as Map).containsKey('url')) {
            safeImages = list.map((e) => e['url'].toString()).toList();
          } 
          // 情況 B: 普通字串陣列 ["...", "..."]
          else {
            safeImages = list.map((e) => e.toString()).toList();
          }
        }
      } else if (json['imageUrl'] != null) {
        // 兼容舊資料單張圖
        safeImages = [json['imageUrl'].toString()];
      }
    } catch (e) {
      print("圖片解析錯誤: $e");
    }
    
    // 預設圖防呆
    if (safeImages.isEmpty) {
      safeImages = ['https://via.placeholder.com/400?text=No+Image'];
    }

    // --- 2. 價格解析防呆 ---
    double safePrice = 0;
    try {
      if (json['price'] != null) {
        // 如果是數字直接轉
        if (json['price'] is num) {
           safePrice = (json['price'] as num).toDouble();
        } 
        // 如果是字串嘗試 parse
        else if (json['price'] is String) {
           safePrice = double.tryParse(json['price']) ?? 0;
        }
      }
    } catch (e) {
      print("價格解析錯誤: $e");
    }

    // --- 3. 類別解析 ---
    List<String> safeCategories = [];
    if (json['categories'] != null && json['categories'] is List) {
      safeCategories = (json['categories'] as List).map((e) => e.toString()).toList();
    }

    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '精選商品',
      price: safePrice,
      images: safeImages,
      description: json['description']?.toString() ?? '暫無說明',
      deepLink: json['deepLink']?.toString() ?? '',
      categories: safeCategories,
    );
  }
}