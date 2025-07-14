// ===============================
// RecipeVault – MVP Skeleton (UTF‑8) 2025‑07‑06
// Flutter 3.22 • Dart 3.4
// ===============================
// * FirebaseAuth で匿名認証 → Firestore 読み込み可
// * RewardedAd 視聴で保存枠 +5（実機のみ）
// * firebase_options.dart は **FlutterFire CLI** が生成 → 本リポには含めない
// ───────────────────────────────────────────

/* pubspec.yaml */
name: recipe_vault
version: 0.3.0

environment:
  sdk: '>=3.4.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^3.15.1
  firebase_auth: ^5.10.0
  cloud_firestore: ^5.6.11
  provider: ^6.1.5
  intl: any
  google_mobile_ads: ^6.0.0

dev_dependencies:
  flutter_lints: ^5.0.0

// ───────────────────────── lib/main.dart ─────────────────────────
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'services/recipe_service.dart';
import 'services/ad_service.dart';
import 'pages/home_page.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAuth.instance.signInAnonymously();
  if (!kIsWeb) await AdService.initMobileAds();
  runApp(const RecipeVaultApp());
}

class RecipeVaultApp extends StatelessWidget {
  const RecipeVaultApp({super.key});
  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => RecipeService()),
          Provider(create: (_) => AdService()),
        ],
        child: MaterialApp(
          title: 'RecipeVault',
          theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.green), useMaterial3: true),
          home: const HomePage(),
        ),
      );
}

// ───────────────────── lib/models/recipe.dart ─────────────────────
import 'package:cloud_firestore/cloud_firestore.dart';

class Recipe {
  Recipe({required this.id, required this.title, required this.ingredients, required this.steps, required this.createdAt});
  final String id;
  final String title;
  final List<String> ingredients;
  final String steps;
  final DateTime createdAt;
  factory Recipe.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) => Recipe.fromJson(doc.id, doc.data()!);
  factory Recipe.fromJson(String id, Map<String, dynamic> json) => Recipe(
        id: id,
        title: json['title'] as String,
        ingredients: List<String>.from(json['ingredients'] as List),
        steps: json['steps'] as String,
        createdAt: (json['createdAt'] as Timestamp).toDate(),
      );
  Map<String, dynamic> toJson() => {
        'title': title,
        'ingredients': ingredients,
        'steps': steps,
        'createdAt': createdAt,
      };
}

// ─────────────────── lib/services/recipe_service.dart ───────────────────
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/recipe.dart';

class RecipeService extends ChangeNotifier {
  static const int initialQuota = 30;
  static const int incrementPerAd = 5;
  final _root = FirebaseFirestore.instance.collection('recipes');
  int _quota = initialQuota;
  int get quota => _quota;

  Stream<List<Recipe>> streamRecipes(String uid) => _root
      .doc(uid)
      .collection('items')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Recipe.fromDoc).toList());

  Future<void> addRecipe(String uid, Recipe r) async {
    final count = await _root.doc(uid).collection('items').count().get().then((c) => c.count);
    if (count >= _quota) throw Exception('枠上限に達しています');
    await _root.doc(uid).collection('items').add(r.toJson());
  }

  void expandQuota() {
    _quota += incrementPerAd;
    notifyListeners();
  }
}

// ─────────────────── lib/services/ad_service.dart ───────────────────
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'recipe_service.dart';

class AdService {
  static const _rewardedId = 'ca-app-pub-3940256099942544/5224354917';
  RewardedAd? _rewardedAd;
  static Future<void> initMobileAds() async {
    if (kIsWeb) return;
    await MobileAds.instance.initialize();
  }

  Future<void> showRewardedAd(BuildContext context) async {
    if (kIsWeb) return;
    if (_rewardedAd == null) await _loadAd();
    if (_rewardedAd == null) return;
    _rewardedAd!.show(onUserEarnedReward: (_, __) {
      context.read<RecipeService>().expandQuota();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存枠が +5 追加されました！')));
    });
    _rewardedAd = null;
  }

  Future<void> _loadAd() async => RewardedAd.load(
        adUnitId: _rewardedId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) => _rewardedAd = ad,
          onAdFailedToLoad: (e) => debugPrint('Ad load failed: $e'),
        ),
      );
}

// ─────────────────── lib/pages/home_page.dart ───────────────────
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/recipe_service.dart';
import '../services/ad_service.dart';
import '../models/recipe.dart';
import 'edit_recipe_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    final recipeService = context.watch<RecipeService>();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('認証失敗…再起動してください')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('My Recipes')),
      body: StreamBuilder<List<Recipe>>(
        stream: recipeService.streamRecipes(uid),
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final recipes = snap.data!;
          return ListView.separated(
            itemCount: recipes.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final r = recipes[i];
              return ListTile(
                title: Text(r.title),
                subtitle: Text(r.ingredients.join(', ')),
                trailing: Text(DateFormat.yMd().format(r.createdAt)),
              );
            },
          );
        },
      ),
      floatingActionButton: FutureBuilder<int>(
        future: FirebaseFirestore.instance.collection('recipes').doc(uid).collection('items').count().get().then((c) => c.count),
        builder: (_, snap) {
          final count = snap.data ?? 0;
          final isFull = count >= recipeService.quota;
          if (kIsWeb && isFull) {
            return FloatingActionButton.extended(onPressed: null, label: const Text('枠上限です'), icon: const Icon(Icons.block));
          }
          return FloatingActionButton.extended(
            onPressed: isFull ? () => context.read<AdService>().showRewardedAd(context) : () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditRecipePage(uid: uid))),
            icon: Icon(isFull ? Icons.play_circle : Icons.add),
            label: Text(isFull ? '+5枠 (広告)' : '新規追加'),
          );
        },
      ),
    );
  }
}

// ─────────────── lib/pages/edit_recipe_page.dart ───────────────
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models
