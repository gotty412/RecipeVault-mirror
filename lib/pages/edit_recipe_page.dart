import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recipe.dart';
import '../services/recipe_service.dart';
import '../services/ad_service.dart';

class EditRecipePage extends StatefulWidget {
  const EditRecipePage({
    super.key,
    required this.uid,
  });

  final String uid;

  @override
  State<EditRecipePage> createState() => _EditRecipePageState();
}

class _EditRecipePageState extends State<EditRecipePage> {
  final _titleCtrl       = TextEditingController();
  final _ingredientsCtrl = TextEditingController();
  final _stepsCtrl       = TextEditingController();
  final _formKey         = GlobalKey<FormState>();

  bool _isLoading   = true;
  int  _quota       = 0;
  int  _currentCnt  = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // ── データ取得 ─────────────────────────────
    final recipeService = context.read<RecipeService>();
    final recipe        = await recipeService.fetchRecipe(widget.uid);

    if (!mounted) return;           // ← State が破棄されたら中断

    _titleCtrl.text       = recipe.title;
    _ingredientsCtrl.text = recipe.ingredients;
    _stepsCtrl.text       = recipe.steps;
    _quota                = recipeService.quota;
    _currentCnt           = recipeService.count;

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _ingredientsCtrl.dispose();
    _stepsCtrl.dispose();
    super.dispose();
  }

  // ── 保存処理 ──────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // BuildContext を避けて事前に取得
    final navigator         = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final recipeService     = context.read<RecipeService>();

    await recipeService.updateRecipe(
      uid:         widget.uid,
      title:       _titleCtrl.text.trim(),
      ingredients: _ingredientsCtrl.text.trim(),
      steps:       _stepsCtrl.text.trim(),
    );

    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('保存しました')),
    );

    navigator.pop();               // 画面を閉じる
  }

  // ── 広告視聴で枠拡張 ────────────────────────────
  Future<void> _expandQuota() async {
    final adWatched = await context.read<AdService>().showRewardedAd();
    if (!adWatched) return;

    await context.read<RecipeService>().expandQuota(5);

    if (!context.mounted) return;
    Navigator.of(context).pop();   // 1 つ前の画面に戻って再描画
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final reachedLimit = _currentCnt >= _quota;

    return Scaffold(
      appBar: AppBar(
        title: const Text('レシピを編集'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text('$_currentCnt / $_quota'),
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
                decoration: const InputDecoration(labelText: '材料'),
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
  }
}
