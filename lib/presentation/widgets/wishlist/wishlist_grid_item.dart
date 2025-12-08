import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class WishlistGridItem extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const WishlistGridItem({
    super.key,
    required this.data,
    required this.onTap,
    required this.onDelete,
  });

  // ★ 新增這個輔助函式：用來安全地取得圖片網址
  String _getSafeImageUrl(dynamic imageData) {
    if (imageData == null) return '';
    
    // 情況 1: 如果是標準的 String，直接回傳
    if (imageData is String) {
      return imageData;
    } 
    // 情況 2: 如果不小心存成了 List (陣列)，就拿第一張圖
    else if (imageData is List && imageData.isNotEmpty) {
      return imageData.first.toString();
    }
    
    return '';
  }

  @override
  Widget build(BuildContext context) {
    // ★ 在這裡使用防呆函式
    // 優先讀 imageUrl，如果它是 List 函式會處理
    // 如果 imageUrl 是空的，試著讀 images 欄位
    final String displayImage = _getSafeImageUrl(data['imageUrl'] ?? data['images']);

    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: displayImage.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: displayImage, // ★ 使用處理過的變數
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (context, url) => Container(color: Colors.grey[200]),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Center(child: Icon(Icons.image_not_supported, color: Colors.grey)),
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] ?? '未知商品',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "NT\$ ${data['price']}",
                        style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 5,
              right: 5,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}