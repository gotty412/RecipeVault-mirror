import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recipe.dart';
import '../services/recipe_service.dart';
import '../services/ad_service.dart';

/// レシピ新規追加ページ
class EditRecipePage extends StatefulWidget {
  const EditRecipePage({super.key, required this.uid});
  final String uid;

  @override
  State<EditRecipePage> createState() => _EditRecipePageState();
}

class _EditRecipePageState extends State<EditRecipePage> {
  final _title       = TextEditingController();
  final _ingredients = TextEditingController();
  final _steps       = TextEditingController();
  final _formKey     = GlobalKey<FormState>();

  @override
  void dispose() {
    _title.dispose();
    _ingredients.dispose();
    _steps.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('レシピを追加')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                // ─────────── タイトル
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(labelText: 'タイトル'),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? '必須です' : null,
                ),
                // ─────────── 材料
                TextFormField(
                  controller: _ingredients,
                  decoration:
                      const InputDecoration(labelText: '材料（カンマ区切り）'),
                ),
                // ─────────── 手順
                TextFormField(
                  controller: _steps,
                  decoration: const InputDecoration(labelText: '手順'),
                  maxLines: 6,
                ),
                const SizedBox(height: 16),

                // ─────────── 保存ボタン
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('保存'),
                  onPressed: () async {
                    // フォーム検証
                    if (!_formKey.currentState!.validate()) return;

                    // 入力値をモデルへ
                    final recipe = Recipe(
                      id: '',
                      title: _title.text.trim(),
                      ingredients: _ingredients.text
                          .split(',')
                          .map((e) => e.trim())
                          .toList(),
                      steps: _steps.text.trim(),
                      createdAt: DateTime.now(),
                    );

                    // Provider は await 前に取得
                    final recipeService = context.read<RecipeService>();

                    try {
                      await recipeService.addRecipe(recipe);

                      if (!mounted) return; // await 後に必ず mounted チェック
                      Navigator.of(context).pop();
                    } catch (e) {
                      if (!mounted) return;

                      // ─── 保存枠オーバー時 ─────────────────────
                      if (e.toString().contains('Quota exceeded')) {
                        final bool? watchAd = await showDialog<bool>(
                          context: context,
                          barrierDismissible: false,
                          builder: (dialogCtx) {
                            final ad = dialogCtx.watch<AdService>();
                            return AlertDialog(
                              title: const Text('保存枠がいっぱいです'),
                              content: const Text(
                                '保存上限 30 件を超えました。\n'
                                '広告を視聴すると保存枠を +5 件拡張できます。',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogCtx).pop(false),
                                  child: const Text('キャンセル'),
                                ),
                                ElevatedButton(
                                  onPressed: ad.isReady
                                      ? () =>
                                          Navigator.of(dialogCtx).pop(true)
                                      : null,
                                  child: ad.isLoading
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('広告を見る'),
                                ),
                              ],
                            );
                          },
                        );

                        // 広告視聴
                        if (watchAd == true && mounted) {
                          final adService = context.read<AdService>();
                          await adService.showRewardedAd(context);
                        }
                      } else {
                        // ─── その他のエラー ─────────────────────
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      );
}
