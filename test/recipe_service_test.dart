import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:recipe_vault/services/recipe_service.dart';

void main() {
  // --- Firebase をモック初期化 -----------------------------
  setupFirebaseCoreMocks();
  setUpAll(() async {
    await Firebase.initializeApp();
  });

  test('expandQuota() で枠が +5 増える', () {
    final service = RecipeService();
    final initial = service.quota;

    service.expandQuota();

    expect(service.quota, initial + 5);
  });
}
