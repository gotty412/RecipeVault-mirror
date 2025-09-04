// lib/services/quota.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class QuotaExceededException implements Exception {}

class QuotaService {
  static final _db = FirebaseFirestore.instance;

  /// 現在の枠状況を取得（null は「不明＝事前判定スキップ」）
  static Future<bool?> canCreate(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      final data = doc.data()!;
      final int recipeCount = (data['recipeCount'] ?? 0) as int;
      final int maxRecipes  = (data['maxRecipes']  ?? 10) as int;
      return recipeCount < maxRecipes;
    } catch (_) {
      return null;
    }
  }
}
