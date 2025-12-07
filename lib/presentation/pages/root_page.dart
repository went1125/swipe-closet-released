import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_page.dart';
import 'onboarding_page.dart';

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  // 0: Loading, 1: Home, 2: Onboarding
  int _pageState = 0; 

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      
      // 1. 如果沒登入，先幫他匿名登入
      if (user == null) {
        await FirebaseAuth.instance.signInAnonymously();
        user = FirebaseAuth.instance.currentUser;
      }

      // 2. 檢查是否填過興趣
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (doc.exists && doc.data()?['isOnboardingCompleted'] == true) {
        setState(() => _pageState = 1); // 去首頁
      } else {
        setState(() => _pageState = 2); // 去興趣選擇頁
      }
    } catch (e) {
      // 出錯保底去首頁
      setState(() => _pageState = 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_pageState) {
      case 0:
        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text("正在整理你的衣櫥...", style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        );
      case 1:
        return const HomePage();
      case 2:
        return const OnboardingPage();
      default:
        return const HomePage();
    }
  }
}