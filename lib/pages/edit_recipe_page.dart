import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recipe.dart';
import '../services/recipe_service.dart';
import '../services/ad_service.dart';

class EditRecipePage extends StatefulWidget {
  const EditRecipePage({super.key});

  @override
  State<EditRecipePage> createState() => _EditRecipePageState();
}

class _EditRecipePageState extends State<EditRecipePage> {
  final _titleCtrl       = TextEditingController();
  final _ingredientsCtrl = TextEditingController();
  final _stepsCtrl       = TextEditingController();
  final _formKey         = GlobalKey<FormState>();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _ingredientsCtrl.dispose();
    _stepsCtrl.dispose();
    super.dispose();
  }

  // ── 保存処理 ────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final navigator         = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final recipeService     = context.read<RecipeService>();

    final newRecipe = Recipe(
      id: '',                               // Firestore 側で自動 ID
      title: _titleCtrl.text.trim(),
      ingredients: _ingredientsCtrl.text
          .trim()
          .split(RegExp(r'[\\n,]'))
          .where((s) => s.isNotEmpty)
          .toList(),
      steps: _stepsCtrl.text.trim(),
      createdAt: DateTime.now(),
    );

    try {
      await recipeService.addRecipe(newRecipe);
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('保存しました')),
      );
      navigator.pop();
    } on Exception catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('保存に失敗しました: ${e.toString()}')),
      );
    }
  }

  // ── 枠拡張（広告視聴）─────────────────────────
  Future<void> _expandQuota() async {
    await context.read<AdService>().showRewardedAd(context);
    if (!mounted) return;
    Navigator.of(context).pop(); // 枠が増えたのでホームへ戻る
  }

  @override
  Widget build(BuildContext context) {
    final recipeService = context.watch<RecipeService>();

    return StreamBuilder<List<Recipe>>(
      stream: recipeService.streamRecipes(),
      builder: (context, snap) {
        final currentCnt   = snap.data?.length ?? 0;
        final quota        = recipeService.quota;
        final reachedLimit = currentCnt >= quota;

        return Scaffold(
          appBar: AppBar(
            title: const Text('レシピを追加'),
            actions: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Text('$currentCnt / $quota'),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: reachedLimit ? _expandQuota : _save,
            label: Text(reachedLimit ? '+5枠 (広告)' : '保存'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(labelText: 'タイトル'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? '入力してください' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _ingredientsCtrl,
                    decoration: const InputDecoration(
                      labelText: '材料（改行またはカンマ区切り）',
                    ),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _stepsCtrl,
                    decoration: const InputDecoration(labelText: '手順'),
                    maxLines: 8,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
