/*
  main.dart  –  “ダークテーマ対応” を最小手数で追加した完全版
  ─────────────────────────────────────────
  ポイントは ❶ 〜 ❸ の 3 か所だけです。
  ❶ MaterialApp に darkTheme / themeMode を追加
  ❷ もし独自カラーを使いたい場合のサンプルをコメントで用意
  ❸ 既存ロジック（匿名ログイン・広告ロードなど）は一切変更なし
*/

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/recipe_service.dart';
import 'services/ad_service.dart';
import 'pages/home_page.dart';

Future<void> main() async {
  // ────────────────────────────────────────────
  // Flutter & Firebase を初期化
  // ────────────────────────────────────────────
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 匿名ログイン（未ログインなら）
  await AuthService().signInAnonymouslyIfNeeded();

  // Mobile Ads SDK を初期化（Web ビルド時は不要）
  if (!kIsWeb) await AdService.initMobileAds();

  // AdService を生成して最初の広告をプリロード
  final adService = AdService();
  await adService.preload();

  // マルチプロバイダで状態を注入してアプリ起動
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RecipeService()),
        ChangeNotifierProvider.value(value: adService),
      ],
      child: const RecipeVaultApp(),
    ),
  );
}

/// アプリ本体
class RecipeVaultApp extends StatelessWidget {
  const RecipeVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RecipeVault',

      // ❶ ─────────────────────────────────────
      // テーマ設定
      //   - theme      : ライトモード用
      //   - darkTheme  : ダークモード用
      //   - themeMode  : 自動切替 (system) を指定
      // ─────────────────────────────────────
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          // ❷ ダーク時のアクセント色を少し落ち着かせたい例
          seedColor: Colors.green.shade700,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode
          .system, // 端末がダークモードなら darkTheme を自動適用（手動切替の余地も残せる）

      // ルートページ
      home: const HomePage(),
    );
  }
}
