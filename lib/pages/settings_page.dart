import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_notifier.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // ドロップダウン（オーバーレイ）制御
  final LayerLink _anchorLink = LayerLink();
  final GlobalKey _buttonKey = GlobalKey(); // 右側ボタンの枠
  final GlobalKey _labelKey  = GlobalKey(); // 右側ボタン内の“現在ラベル”Text
  OverlayEntry? _menuEntry;

  // 見た目定数（固定幅は使わない）
  static const double kPadX = 8;         // ボタン内左右パディング
  static const double kGap = 6;          // ラベルと矢印の間
  static const double kIconW = 24;       // 矢印幅
  static const double kBorder = 1;       // 外枠線
  static const double kMenuInsetLeft  = 12; // メニュー項目の左インセット
  static const double kMenuInsetRight = 12; // メニュー項目の右インセット
  static const double kMenuOffsetY    = 8;  // ボタン下端からの縦オフセット
  static const double kScreenMargin   = 12; // 画面左右の安全マージン
  static const double kMenuMinWidth   = 120;

  String labelOf(ThemeMode m) {
    switch (m) {
      case ThemeMode.system: return 'システム';
      case ThemeMode.light:  return 'ライト';
      case ThemeMode.dark:   return 'ダーク';
    }
  }

  void _closeMenu() {
    _menuEntry?.remove();
    _menuEntry = null;
  }

  void _openMenu(BuildContext ctx, ThemeMode currentMode) {
    _closeMenu();

    final overlayBox = Overlay.of(ctx).context.findRenderObject() as RenderBox;
    final mq = MediaQuery.of(ctx);

    // ボタンとラベルの RenderBox
    final buttonBox = _buttonKey.currentContext!.findRenderObject() as RenderBox;
    final labelCtx  = _labelKey.currentContext!;
    final labelBox  = labelCtx.findRenderObject() as RenderBox;

    // “現在ラベル”Text の実際の style で幅を測る（右寄せ想定）
    final textWidget = labelCtx.widget as Text;
    final labelStyle = textWidget.style ?? DefaultTextStyle.of(labelCtx).style;
    final text       = textWidget.data ?? '';
    final painter = TextPainter(
      text: TextSpan(text: text, style: labelStyle),
      textDirection: Directionality.of(labelCtx),
      maxLines: 1,
    )..layout();

    // 右寄せ → 文字の左端 = ラベルBox右端 - 文字幅
    final labelTopRightGlobal = labelBox.localToGlobal(
      Offset(labelBox.size.width, 0),
      ancestor: overlayBox,
    );
    final glyphLeftGlobalX = labelTopRightGlobal.dx - painter.width;

    // ボタン左上（グローバル）
    final buttonTopLeftGlobal = buttonBox.localToGlobal(Offset.zero, ancestor: overlayBox);

    // メニューの中身（現在以外の2つ）
    const all = [ThemeMode.system, ThemeMode.light, ThemeMode.dark];
    final others = all.where((m) => m != currentMode).toList();
    final labels = others.map(labelOf).toList();

    // —— 予測メニュー幅を計測し、画面内に収まるよう X をクランプ —— //
    final menuTextStyle = Theme.of(ctx).textTheme.bodyMedium ?? const TextStyle();
    double contentMax = 0;
    for (final s in labels) {
      final tp = TextPainter(
        text: TextSpan(text: s, style: menuTextStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      contentMax = math.max(contentMax, tp.width);
    }
    final estimatedMenuWidth = math.max(
      kMenuMinWidth,
      contentMax + kMenuInsetLeft + kMenuInsetRight,
    );

    final viewportWidth = overlayBox.size.width;
    final safeLeft  = kScreenMargin + mq.padding.left;
    final safeRight = viewportWidth - (kScreenMargin + mq.padding.right);

    // 理想の左座標（“現在ラベルの文字左端”に合わせてメニュー左端を置く）
    double desiredLeft = glyphLeftGlobalX - kMenuInsetLeft;
    // 右はみ出しなら左へ寄せ、左はみ出しなら右へ戻す
    if (desiredLeft + estimatedMenuWidth > safeRight) {
      desiredLeft = safeRight - estimatedMenuWidth;
    }
    if (desiredLeft < safeLeft) {
      desiredLeft = safeLeft;
    }
    final clampedDx = desiredLeft - buttonTopLeftGlobal.dx;
    final dy = buttonBox.size.height + kMenuOffsetY;

    // OverlayEntry
    _menuEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(onTap: _closeMenu, behavior: HitTestBehavior.opaque),
            ),
            CompositedTransformFollower(
              link: _anchorLink,
              showWhenUnlinked: false,
              offset: Offset(clampedDx, dy),
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: kMenuMinWidth, maxWidth: safeRight - safeLeft),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: others.map((m) {
                      return InkWell(
                        onTap: () {
                          context.read<ThemeNotifier>().update(m);
                          _closeMenu();
                        },
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(kMenuInsetLeft, 10, kMenuInsetRight, 10),
                          child: Text(labelOf(m), style: menuTextStyle),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(ctx).insert(_menuEntry!);
  }

  @override
  void dispose() {
    _closeMenu();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier   = context.watch<ThemeNotifier>();
    final mode       = notifier.mode;
    final labelText  = labelOf(mode);
    final labelStyle = Theme.of(context).textTheme.bodyMedium; // 現在値のサイズを明示

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            // ListTile をやめ、Row で幅配分を制御
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左：タイトル + 説明（できるだけ広く取り、説明は 1 行固定）
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ダークテーマ',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ライト / ダーク / 端末設定に従う',
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.fade,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // 右：現在設定ドロップダウン（中身ぶんだけの最小幅）
                CompositedTransformTarget(
                  link: _anchorLink,
                  child: InkWell(
                    onTap: () => _openMenu(context, mode),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      key: _buttonKey,
                      padding: const EdgeInsets.symmetric(horizontal: kPadX, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).dividerColor, width: kBorder),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              key: _labelKey,
                              labelText,
                              style: labelStyle,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                          ),
                          const SizedBox(width: kGap),
                          const Icon(Icons.arrow_drop_down, size: kIconW),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
