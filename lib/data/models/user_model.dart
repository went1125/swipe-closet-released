// lib/data/models/user_model.dart

class UserModel {
  final String uid;
  final String gender;
  final List<String> styles;
  final List<String> categories;
  final double priceMin;
  final double priceMax;
  final List<String> excludedPlatforms;
  final bool isAnonymous;

  UserModel({
    required this.uid,
    required this.gender,
    required this.styles,
    required this.categories,
    this.priceMin = 0,
    this.priceMax = 5000,
    this.excludedPlatforms = const [],
    this.isAnonymous = true,
  });

  // 轉成 Map 存入 Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'gender': gender,
      'preferences': {
        'styles': styles,
        'categories': categories,
        'priceMin': priceMin,
        'priceMax': priceMax,
        'excludedPlatforms': excludedPlatforms,
      },
      'isAnonymous': isAnonymous,
      'lastActive': DateTime.now().toIso8601String(),
    };
  }

  // 從 Firestore 讀取
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    final prefs = map['preferences'] ?? {};
    return UserModel(
      uid: uid,
      gender: map['gender'] ?? 'female',
      styles: List<String>.from(prefs['styles'] ?? []),
      categories: List<String>.from(prefs['categories'] ?? []),
      priceMin: (prefs['priceMin'] ?? 0).toDouble(),
      priceMax: (prefs['priceMax'] ?? 5000).toDouble(),
      excludedPlatforms: List<String>.from(prefs['excludedPlatforms'] ?? []),
      isAnonymous: map['isAnonymous'] ?? true,
    );
  }
}