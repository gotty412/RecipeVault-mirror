import 'package:flutter_test/flutter_test.dart';
import 'package:recipe_vault/services/recipe_service.dart';

void main() {
  test('expandQuota() で枠が +5 増える', () {
    final service  = RecipeService();   // 依存先にはまだ触れない
    final initial  = service.quota;

    service.expandQuota();              // 1 度呼ぶ

    expect(service.quota, initial + 5); // ★ 合計が +5 になっているか
  });
}
