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
  // ── Flutter & Firebase 初期化 ───────────────────────────────
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ── 匿名ログイン（未ログインなら）───────────────────────────
  await AuthService().signInAnonymouslyIfNeeded();

  // ── Mobile Ads SDK 初期化 ───────────────────────────────────
  if (!kIsWeb) await AdService.initMobileAds();

  // ── AdService を生成して最初の広告をプリロード ──────────────
  final adService = AdService();
  await adService.preload();

  // ── アプリ起動 ──────────────────────────────────────────────
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RecipeService()),
        ChangeNotifierProvider.value(value: adService), // ← 状態を通知
      ],
      child: const RecipeVaultApp(),
    ),
  );
}

class RecipeVaultApp extends StatelessWidget {
  const RecipeVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RecipeVault',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
