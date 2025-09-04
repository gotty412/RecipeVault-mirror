/*
  main.dart  –  “ダークテーマ対応” を最小手数で追加した改訂版
  ─────────────────────────────────────────
  ポイントは ❶ 〜 ❸ の 3 か所です。
  ❶ MaterialApp に darkTheme / themeMode を追加（ライト/ダーク自動切替）
  ❷ 初期化：Firebase → 匿名ログイン → Mobile Ads（Webはスキップ）
  ❸ AdService は Provider のライフサイクルに任せて生成し、..preload() で広告を準備
*/

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:recipe_vault/theme_notifier.dart';

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

  // Provider で状態を注入してアプリ起動
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RecipeService()),
        // AdService は Provider 管理にして、起動時に広告をプリロード
        ChangeNotifierProvider(create: (_) => AdService()..preload()),
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
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
          seedColor: Colors.greenAccent.shade700,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: context.watch<ThemeNotifier>().mode,

      // ルートページ
      home: const HomePage(),
    );
  }
}
