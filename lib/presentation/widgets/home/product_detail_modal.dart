import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/product_model.dart';

class ProductDetailModal extends StatelessWidget {
  final Product product;

  const ProductDetailModal({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    // 使用 DraggableScrollableSheet 讓它可以往上滑動展開
    return DraggableScrollableSheet(
      initialChildSize: 0.6, // 初始高度 60%
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // 頂部把手 (Handle)
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              // 內容捲動區
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    Text(product.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("NT\$ ${product.price.toInt()}", style: const TextStyle(fontSize: 24, color: Colors.pinkAccent, fontWeight: FontWeight.w900)),
                    const Divider(height: 30),
                    
                    const Text("商品詳情", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      product.description,
                      style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    
                    // 這裡可以展示全部圖片的縮圖列表
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: product.images.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, index) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: product.images[index],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 100), // 底部留白
                  ],
                ),
              ),
              
              // 底部固定購買按鈕
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => _launchUrl(context, product.deepLink),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    child: const Text("前往購買", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

Future<void> _launchUrl(BuildContext context, String url) async {
    // 1. 防呆檢查：連結是否為空？
    if (url.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ 商品連結無效或為空"),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 1),
          ),
        );
      }
      return;
    }

    // 2. 印出 Log，讓你知道現在到底在開什麼連結
    debugPrint("🚀 準備開啟連結: $url");

    try {
      final Uri uri = Uri.parse(url);

      // 3. 嘗試開啟 (邏輯優化)
      // 優先嘗試用外部 App (LaunchMode.externalNonBrowserApplication)
      // 如果手機沒裝蝦皮，這行會回傳 false，或是拋出錯誤
      bool launched = false;
      try {
        launched = await launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication);
      } catch (e) {
        // 忽略這裡的錯誤，繼續嘗試用瀏覽器開
        debugPrint("無法以 App 開啟，嘗試使用瀏覽器...");
      }

      // 4. 如果 App 開不起來，改用瀏覽器開啟 (LaunchMode.externalApplication)
      if (!launched) {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }

      // 5. 如果連瀏覽器都開不起來，報錯
      if (!launched) {
        throw Exception("無法開啟任何瀏覽器或 App");
      }

    } catch (e) {
      debugPrint("❌ 開啟失敗: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("無法開啟連結: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}