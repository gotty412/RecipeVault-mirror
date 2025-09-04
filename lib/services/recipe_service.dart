import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/recipe.dart';
import 'quota.dart';

class RecipeService extends ChangeNotifier {
  static const int initialQuota   = 10;
  static const int incrementPerAd = 5;
  int _quota = initialQuota;
  int get quota => _quota;

  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _itemsRef() =>
      _db.collection('recipes')
         .doc(FirebaseAuth.instance.currentUser!.uid)
         .collection('items');

  Future<void> _ensureUserDoc() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = _db.collection('users').doc(uid);
    await ref.set({
      'maxRecipes': _quota, // 初回は 10、後で Functions が上書き可
      'recipeCount': FieldValue.increment(0), // 数値フィールドを確実に作る
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<Recipe>> streamRecipes() => _itemsRef()
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => Recipe.fromJson(d.id, d.data())).toList());

  Future<void> addRecipe(Recipe r) async {
    await _ensureUserDoc(); // ← まず作っておく

    final count = await _itemsRef().get().then((s) => s.size);
    if (count >= _quota) {
      throw QuotaExceededException();
    }

    await _itemsRef().add({
      ...r.toJson(),
      'uid': FirebaseAuth.instance.currentUser!.uid, // ルールの緩和条件にも対応
      'createdAt': FieldValue.serverTimestamp(),     // サーバ時刻で確定
    });
  }

  Future<void> deleteRecipe(String docId) async {
    await _itemsRef().doc(docId).delete();
  }

  void expandQuota() {
    _quota += incrementPerAd;
    notifyListeners();
  }
}
