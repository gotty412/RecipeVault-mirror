// lib/services/ad_service.dart
import 'dart:async';

import 'package:flutter/foundation.dart' show ChangeNotifier, kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:uuid/uuid.dart';

import 'recipe_service.dart';

class AdService with ChangeNotifier {
  // テストID（本番では差し替え）
  static const _rewardedId = 'ca-app-pub-3940256099942544/5224354917';

  RewardedAd? _ad;
  bool _loading = false;

  bool get isReady => _ad != null;
  bool get isLoading => _loading;

  static Future<void> initMobileAds() async {
    if (kIsWeb) return;
    await MobileAds.instance.initialize();
  }

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
          Future<void>.delayed(const Duration(seconds: 5), preload);
        },
      ),
    );
  }

  /// リワード広告を表示 → Functions で枠付与 → UIに即時反映
  Future<void> showRewardedAd(BuildContext context) async {
    if (kIsWeb || _ad == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final recipeService = context.read<RecipeService>();

    _ad!.show(onUserEarnedReward: (_, __) async {
      try {
        // ❶ Functions を呼んで server 側で上限を増分（冪等ID付き）
        final eventId = const Uuid().v4();
        final functions = FirebaseFunctions.instanceFor(region: 'asia-northeast1');
        final callable  = functions.httpsCallable('grantReward');
        await callable.call(<String, dynamic>{
          'amount': RecipeService.incrementPerAd,
          'eventId': eventId,
        });

        // ❷ UI も即時反映
        recipeService.expandQuota();
        messenger.showSnackBar(
          const SnackBar(content: Text('保存枠が +5 追加されました！')),
        );
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(content: Text('枠の付与に失敗しました: $e')),
        );
      }
    });

    _ad = null;
    await preload();
  }

  /// 互換: 既存コードがこの名前を呼んでいても動くように
  Future<void> showRewardAdAndGrant(BuildContext context) =>
      showRewardedAd(context);
}
