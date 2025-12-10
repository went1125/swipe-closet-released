// lib/presentation/widgets/home/filter_settings_modal.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FilterSettingsModal extends StatefulWidget {
  const FilterSettingsModal({super.key});

  @override
  State<FilterSettingsModal> createState() => _FilterSettingsModalState();
}

class _FilterSettingsModalState extends State<FilterSettingsModal> {
  // 狀態變數
  RangeValues _priceRange = const RangeValues(0, 3000);
  final List<String> _platforms = ["Shopee", "Momo", "iChannels"];
  final List<String> _excludedPlatforms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  // 從 Firestore 載入設定
  Future<void> _loadUserPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (doc.exists) {
          final prefs = doc.data()?['preferences'] ?? {};
          setState(() {
            _priceRange = RangeValues(
              (prefs['priceMin'] ?? 0).toDouble(),
              (prefs['priceMax'] ?? 3000).toDouble(),
            );
            _excludedPlatforms
                .addAll(List<String>.from(prefs['excludedPlatforms'] ?? []));
          });
        }
      } catch (e) {
        debugPrint("讀取設定失敗: $e");
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      height: 600, // 固定高度
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                    child: Container(
                        width: 40, height: 4, color: Colors.grey[300])),
                const SizedBox(height: 20),
                const Text("篩選設定",
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),

                const SizedBox(height: 30),
                // 1. 價格範圍滑桿
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("價格範圍",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(
                        "NT\$${_priceRange.start.toInt()} - NT\$${_priceRange.end.toInt()}"),
                  ],
                ),
                RangeSlider(
                  values: _priceRange,
                  min: 0,
                  max: 5000,
                  divisions: 50,
                  activeColor: Colors.black,
                  labels: RangeLabels("NT\$${_priceRange.start.toInt()}",
                      "NT\$${_priceRange.end.toInt()}"),
                  onChanged: (values) {
                    setState(() => _priceRange = values);
                  },
                ),

                const SizedBox(height: 30),
                // 2. 平台篩選
                const Text("顯示平台來源",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: _platforms.map((platform) {
                    // 如果不在排除名單內，就是選中
                    final isSelected =
                        !_excludedPlatforms.contains(platform.toLowerCase());
                    return FilterChip(
                      label: Text(platform),
                      selected: isSelected,
                      selectedColor: Colors.black,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            // 選中 = 從排除名單移除
                            _excludedPlatforms.remove(platform.toLowerCase());
                          } else {
                            // 取消選中 = 加入排除名單
                            _excludedPlatforms.add(platform.toLowerCase());
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

                const Spacer(),
                // 儲存按鈕
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _savePreferences,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white),
                    child: const Text("套用設定"),
                  ),
                )
              ],
            ),
    );
  }

  Future<void> _savePreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'preferences': {
          'priceMin': _priceRange.start,
          'priceMax': _priceRange.end,
          'excludedPlatforms': _excludedPlatforms,
        }
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pop(context);
        // 這裡可以考慮加上 ref.refresh(productProvider) 的通知
      }
    }
  }
}