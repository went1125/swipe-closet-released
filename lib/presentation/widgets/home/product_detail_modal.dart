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
                    onPressed: () => _launchShopee(context, product.deepLink),
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

  Future<void> _launchShopee(BuildContext context, String url) async {
     final Uri uri = Uri.parse(url);
     try {
       if (!await launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication)) {
         await launchUrl(uri, mode: LaunchMode.externalApplication);
       }
     } catch (e) {
       debugPrint("無法開啟連結");
     }
  }
}