import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/categories.dart';
import 'root_page.dart'; 

// 引入剛剛拆好的 Widgets
import '../widgets/onboarding/section_title.dart';
import '../widgets/onboarding/gender_selector.dart';
import '../widgets/onboarding/interest_chip_grid.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final Set<String> _selectedTags = {};
  String _selectedGender = AppCategories.genders[1]; // 預設女裝
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // 頭部標題
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("打造你的專屬衣櫥", 
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text("選擇你感興趣的風格與單品，\n我們將為你推薦最適合的商品。", 
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            // 捲動內容區
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. 性別選擇
                    const SectionTitle(title: "我想看"),
                    GenderSelector(
                      options: AppCategories.genders,
                      selectedOption: _selectedGender,
                      onSelected: (val) => setState(() => _selectedGender = val),
                    ),
                    const SizedBox(height: 24),
                    
                    // 2. 風格選擇
                    const SectionTitle(title: "喜歡的風格"),
                    InterestChipGrid(
                      items: AppCategories.styles,
                      selectedItems: _selectedTags,
                      onToggle: _toggleTag,
                    ),
                    const SizedBox(height: 24),
                    
                    // 3. 單品選擇
                    const SectionTitle(title: "感興趣的單品"),
                    InterestChipGrid(
                      items: AppCategories.items,
                      selectedItems: _selectedTags,
                      onToggle: _toggleTag,
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // 底部按鈕
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _selectedTags.isEmpty ? null : _submitPreferences,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              elevation: 5,
            ),
            child: _isLoading 
              ? const CircularProgressIndicator(color: Colors.white)
              : Text("開始探索 (${_selectedTags.length})", 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  Future<void> _submitPreferences() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'gender': _selectedGender,
          'preferences': _selectedTags.toList(),
          'isOnboardingCompleted': true, // 關鍵標記
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const RootPage()),
          );
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}