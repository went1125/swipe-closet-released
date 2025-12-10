// lib/presentation/providers/product_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/product_model.dart';

final productProvider = FutureProvider<List<Product>>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  
  // 1. 預設演算法參數
  double minPrice = 0;
  double maxPrice = 20000; // 預設上限拉高一點
  List<String> userInterests = []; // 用戶感興趣的類別

  // 2. 讀取使用者畫像 (Persona)
  if (user != null) {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final prefs = doc.data()?['preferences'];
        // 確保 prefs 是 Map 且不為空
        if (prefs != null && prefs is Map) {
          minPrice = (prefs['priceMin'] ?? 0).toDouble();
          maxPrice = (prefs['priceMax'] ?? 20000).toDouble();
          
          if (prefs['categories'] != null && prefs['categories'] is List) {
            userInterests = List<String>.from(prefs['categories']);
          }
        }
      }
    } catch (e) {
      print("讀取用戶偏好失敗 (使用預設值): $e");
    }
  }

  // 3. 執行精準查詢 (Filtering)
  Query query = FirebaseFirestore.instance.collection('products');

  // A. 價格過濾
  query = query
      .where('price', isGreaterThanOrEqualTo: minPrice)
      .where('price', isLessThanOrEqualTo: maxPrice);

  // B. 類別匹配 (演算法核心)
  // 如果用戶有明確興趣，我們優先抓取該類別
  // 注意：Firestore 的 whereIn/arrayContainsAny 查詢可能需要建立複合索引
  if (userInterests.isNotEmpty) {
    // 為了避免索引報錯，初期先抓多一點回來做 Client-side filter，或者只抓前 10 個類別
    query = query.where('categories', arrayContainsAny: userInterests.take(10).toList());
  }

  // C. 限制數量
  // 抓取 50 筆最新或隨機的商品
  final snapshot = await query.limit(50).get();

  // 4. 資料轉換與最終清洗
  var products = snapshot.docs.map((doc) {
    // 把 doc.data() 轉成 Map<String, dynamic>
    final data = doc.data() as Map<String, dynamic>;
    // 注入 ID 以防萬一
    data['id'] = doc.id;
    return Product.fromJson(data);
  }).toList();

  // 5. 隨機洗牌 (Shuffle) - Tinder 模式必備
  products.shuffle();

  return products;
});