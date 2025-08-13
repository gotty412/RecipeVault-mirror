import 'dart:async';

import 'package:flutter/foundation.dart' show ChangeNotifier, kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import 'recipe_service.dart';

class AdService with ChangeNotifier {
  // ★本番ではご自身のリワード広告ユニット ID に差し替えてください
  static const _rewardedId = 'ca-app-pub-3940256099942544/5224354917';

  RewardedAd? _ad;
  bool _loading = false;

  /// --- 状態参照用 ---
  bool get isReady   => _ad != null;
  bool get isLoading => _loading;

  /// --- SDK 初期化 ---
  static Future<void> initMobileAds() async {
    if (kIsWeb) return;
    await MobileAds.instance.initialize();
  }

  /// --- 広告をプリロード ---
  Future<void> preload() async {
    if (kIsWeb || _loading || _ad != null) return;

    _loading = true;
    notifyListeners();

    await RewardedAd.load(
      adUnitId: _rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loading = false;
          notifyListeners();
        },
        onAdFailedToLoad: (err) {
          debugPrint('Ad load failed: $err');
          _loading = false;
          notifyListeners();
          // 5 秒後にリトライ
          Future<void>.delayed(const Duration(seconds: 5), preload);
        },
      ),
    );
  }

  /// --- 広告を表示（報酬付与） ---
  Future<void> showRewardedAd(BuildContext context) async {
    if (kIsWeb || _ad == null) return;

    _ad!.show(onUserEarnedReward: (_, __) {
      // 保存枠 +5
      context.read<RecipeService>().expandQuota();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存枠が +5 追加されました！')),
      );
    });

    _ad = null;
    await preload(); // 次に備えてプリロード
  }
}
