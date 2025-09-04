// ignore_for_file: depend_on_referenced_packages, invalid_use_of_internal_member
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:recipe_vault/services/recipe_service.dart';

void main() {
  // ① テスト用 Flutter バインディングを初期化
  TestWidgetsFlutterBinding.ensureInitialized();

  // ② Firebase モックを設定
  setupFirebaseCoreMocks();

  setUpAll(() async {
    // ③ ダミーの Firebase App を初期化
    await Firebase.initializeApp();
  });

  test('expandQuota() で枠が +5 増える', () {
    final service = RecipeService();
    final initial = service.quota;

    service.expandQuota();

    expect(service.quota, initial + 5);
  });
}
