// lib/presentation/pages/wishlist_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../data/models/product_model.dart';
import '../widgets/wishlist/wishlist_grid_item.dart';
import '../widgets/home/product_detail_modal.dart';

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("尚未登入")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("我的收藏", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favorites')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("還沒有收藏任何商品喔", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              
              return WishlistGridItem(
                data: data,
                onTap: () => _showProductDetail(context, data), 
                onDelete: () => _confirmDelete(context, user.uid, doc.id),
              );
            },
          );
        },
      ),
    );
  }

  // ★ 修正重點：這裡加入了嚴格的型別轉換與防呆邏輯
  void _showProductDetail(BuildContext context, Map<String, dynamic> data) {
    // 1. 處理圖片：不管後端給什麼，都硬轉成 List<String>
    List<String> safeImages = [];
    
    if (data['images'] != null && data['images'] is List && (data['images'] as List).isNotEmpty) {
      // 如果有 images 陣列，把它轉成字串陣列
      safeImages = List<String>.from((data['images'] as List).map((e) => e.toString()));
    } else {
      // 如果沒有 images，檢查 imageUrl
      var singleImg = data['imageUrl'];
      if (singleImg != null) {
        if (singleImg is String && singleImg.isNotEmpty) {
          safeImages = [singleImg];
        } else if (singleImg is List && singleImg.isNotEmpty) {
          // 萬一 imageUrl 誤存成 List，就拿第一張
          safeImages = [singleImg.first.toString()];
        }
      }
    }

    // 如果還是空的，給一張預設圖防止崩潰
    if (safeImages.isEmpty) {
      safeImages = ['https://via.placeholder.com/400'];
    }

    // 2. 建立 Product 物件 (所有欄位都加上 .toString() 防止型別錯誤)
    final product = Product(
      id: data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? '未知商品',
      price: (data['price'] ?? 0).toDouble(),
      images: safeImages,
      description: data['description']?.toString() ?? '暫無說明',
      deepLink: data['deepLink']?.toString() ?? '',
    );

    // 3. 顯示彈窗
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductDetailModal(product: product),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String userId, String docId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("移除收藏"),
        content: const Text("確定要移除這個商品嗎？"),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("取消", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("移除", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('favorites')
            .doc(docId)
            .delete();
            
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("已移除商品"), duration: Duration(milliseconds: 800)),
          );
        }
      } catch (e) {
        debugPrint("刪除失敗: $e");
      }
    }
  }
}