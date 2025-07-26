import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/recipe.dart';
import '../services/recipe_service.dart';
import '../services/ad_service.dart';
import 'edit_recipe_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final recipeService = context.watch<RecipeService>();
    final adService     = context.watch<AdService>();

    return StreamBuilder<List<Recipe>>(
      stream: recipeService.streamRecipes(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ── データ取得 ──────────────────────────────
        final recipes = snap.data!;
        final isFull  = recipes.length >= recipeService.quota;

        return Scaffold(
          // ── AppBar：右端に「登録数 / 上限」バッジを表示 ──────────────
          appBar: AppBar(
            title: Row(
              children: [
                const Text('My Recipes'),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${recipes.length} / ${recipeService.quota}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // ── レシピ一覧 ───────────────────────────────
          body: recipes.isEmpty
              ? const Center(child: Text('まだレシピがありません'))
              : ListView.separated(
                  itemCount: recipes.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final r = recipes[i];
                    return Dismissible(
                      key: ValueKey(r.id),
                      background: Container(
                        alignment: Alignment.centerRight,
                        color: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (dir) async => await showDialog<bool>(
                        context: context,
                        builder: (dialogCtx) => AlertDialog(
                          title: const Text('削除しますか？'),
                          content: Text('「${r.title}」を削除します。よろしいですか？'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogCtx, false),
                              child: const Text('キャンセル'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(dialogCtx, true),
                              child: const Text('削除'),
                            ),
                          ],
                        ),
                      ),
                      onDismissed: (_) => context.read<RecipeService>().deleteRecipe(r.id),
                      child: ListTile(
                        title: Text(r.title),
                        subtitle: Text(r.ingredients.join(', ')),
                        trailing: Text(DateFormat.yMd().format(r.createdAt)),
                      ),
                    );
                  },
                ),

          // ── FAB ─────────────────────────────────────
          floatingActionButton: isFull
              // 保存枠が一杯：広告視聴へ誘導
              ? FloatingActionButton.extended(
                  onPressed: adService.isReady ? () => adService.showRewardedAd(context) : null,
                  icon: adService.isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.play_circle),
                  label: Text(adService.isReady ? '+5 枠 (広告)' : '読み込み中…'),
                )
              // まだ保存枠に余裕あり：新規追加へ
              : FloatingActionButton.extended(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditRecipePage(),   // ← uid 引数を取らない
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('新規追加'),
                ),
        );
      },
    );
  }
}