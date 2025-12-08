import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/product_model.dart';
import 'product_detail_modal.dart'; // 引入剛剛寫的詳情頁

class ProductCard extends StatefulWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  // 控制圖片輪播
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.product.images;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. 圖片層
            CachedNetworkImage(
              imageUrl: images[_currentImageIndex], // 顯示當前索引的圖
              fit: BoxFit.cover,
              placeholder: (c, u) => Container(color: Colors.grey[200]),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),

            // 2. 隱形觸控層 (左邊點一下上一張，右邊點一下下一張)
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_currentImageIndex > 0) {
                        setState(() => _currentImageIndex--);
                      }
                    },
                    child: Container(color: Colors.transparent), // 必須有顏色(透明)才能感應點擊
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_currentImageIndex < images.length - 1) {
                        setState(() => _currentImageIndex++);
                      }
                    },
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ],
            ),

            // 3. 頂部圖片進度條 (像 IG Story)
            if (images.length > 1)
              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: Row(
                  children: List.generate(images.length, (index) {
                    return Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: index == _currentImageIndex
                              ? Colors.white
                              : Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),

            // 4. 底部漸層與資訊
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // 左側：文字資訊
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.product.name,
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            "NT\$ ${widget.product.price.toInt()}",
                            style: const TextStyle(color: Colors.amber, fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    
                    // 右側：詳情按鈕 (i)
                    GestureDetector(
                      onTap: () {
                        // 顯示底部詳情彈窗
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true, // 允許全螢幕高度
                          backgroundColor: Colors.transparent,
                          builder: (context) => ProductDetailModal(product: widget.product),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.info_outline, color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}