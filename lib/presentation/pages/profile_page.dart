// lib/presentation/pages/profile_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart'; // ★ 必須引入

// 引入篩選視窗元件 (請確認路徑正確)
import '../widgets/home/filter_settings_modal.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    // 判斷是否為匿名用戶 (Anonymous)
    final isAnon = user?.isAnonymous ?? true;
    final email = user?.email ?? "尚無 Email";

    return Scaffold(
      appBar: AppBar(title: const Text("個人檔案與設定")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 1. 會員狀態區
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Icon(
                  isAnon ? Icons.person_outline : Icons.verified_user,
                  size: 60,
                  color: isAnon ? Colors.grey : Colors.green,
                ),
                const SizedBox(height: 10),
                Text(
                  isAnon ? "訪客帳號 (資料未備份)" : "正式會員",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                if (!isAnon) 
                   Text(email, style: const TextStyle(color: Colors.grey)),
                
                if (isAnon) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.g_mobiledata),
                    label: const Text("綁定 Google 帳號以永久保存"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _linkGoogleAccount(context),
                  ),
                ]
              ],
            ),
          ),

          const Divider(height: 40),

          // 2. 偏好設定入口
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text("篩選設定"),
            subtitle: const Text("設定價格範圍、排除特定平台"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showFilterModal(context),
          ),

          // 3. 登出按鈕
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("登出", style: TextStyle(color: Colors.red)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // ★ 核心安全邏輯：綁定 Google
  Future<void> _linkGoogleAccount(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // 用戶取消

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 執行綁定
      final userCredential =
          await FirebaseAuth.instance.currentUser?.linkWithCredential(credential);

      // 更新 Firestore 狀態
      if (userCredential?.user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential!.user!.uid)
            .update({
          'isAnonymous': false,
          'email': userCredential.user!.email,
          'lastUpdated': FieldValue.serverTimestamp(),
        });

        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("綁定成功！資料已安全備份")));
        }
      }
    } catch (e) {
      debugPrint("綁定失敗: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("綁定失敗: $e")));
      }
    }
  }

  void _showFilterModal(BuildContext context) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => const FilterSettingsModal());
  }
}