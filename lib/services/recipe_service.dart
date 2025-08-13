import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/recipe.dart';

class RecipeService extends ChangeNotifier {
  // ── 保存枠ロジック ──────────────────────────
  static const int initialQuota   = 10;  // ★ 初期枠を 10 に変更
  static const int incrementPerAd = 5;   // 広告視聴で増える枠
  int _quota = initialQuota;
  int get quota => _quota;

  // ── Firestore ルート ───────────────────────
  final _root = FirebaseFirestore.instance.collection('recipes');

  /// 自分の items コレクション参照
  CollectionReference<Map<String, dynamic>> _itemsRef() =>
      _root.doc(FirebaseAuth.instance.currentUser!.uid).collection('items');

  /// レシピ一覧ストリーム
  Stream<List<Recipe>> streamRecipes() => _itemsRef()
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => Recipe.fromJson(d.id, d.data())).toList());

  /// 追加
  Future<void> addRecipe(Recipe r) async {
    final count = await _itemsRef().get().then((s) => s.size);
    if (count >= _quota) throw Exception('Quota exceeded');
    await _itemsRef().add(r.toJson());
  }

  /// ★ 削除──────────────────────────
  Future<void> deleteRecipe(String docId) async {
    await _itemsRef().doc(docId).delete();
  }

  /// 広告報酬
  void expandQuota() {
    _quota += incrementPerAd;
    notifyListeners();
  }
}
