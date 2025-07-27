# 🍳 RecipeVault

![CI](https://github.com/gotty412/RecipeVault/actions/workflows/flutter_ci.yml/badge.svg)
![coverage](https://codecov.io/gh/gotty412/RecipeVault/branch/main/graph/badge.svg)

&#x20;

Flutter 製 **個人レシピ帳**
広告（リワード）視聴で保存上限を拡張できる MVP 版アプリです。
*“Save your favourite recipes & grow your quota by watching a short ad.”*

|              | 現状                                       |
| ------------ | ---------------------------------------- |
| **初期保存枠**    | 10 件                                     |
| **広告 1 回視聴** | ＋5 件拡張                                   |
| **認証方式**     | 匿名ログイン（`firebase_auth`）                  |
| **バックエンド**   | Cloud Firestore                          |
| **広告 SDK**   | Google Mobile Ads（Rewarded）              |
| **CI / CD**  | GitHub Actions（`flutter analyze` & test） |

---

## 🗺️ 目次

1. [スクリーンショット](#スクリーンショット)
2. [アーキテクチャ](#アーキテクチャ)
3. [📦 環境構築](#-環境構築-約5-分)
4. [💻 開発便利コマンド](#-開発便利コマンド)
5. [🗒️ ブランチ戦略](#️-ブランチ戦略--commit-規約)
6. [📍 今後のロードマップ](#-今後のロードマップ)
7. [🪪 ライセンス](#-ライセンス)

---

## スクリーンショット

| ホーム（残枠あり） | 枠上限→広告提案 | 広告視聴後 Toast |
| --------- | -------- | ----------- |
|           |          |             |

---

## アーキテクチャ

```
Flutter 3.32.5
 ├─ presentation
 │   ├─ pages/          画面 UI
 │   └─ widgets/        共通部品 *(予定)*
 ├─ domain              Model & Service
 │   ├─ models/
 │   └─ services/
 └─ infrastructure
     ├─ Firebase (Auth / Firestore)
     └─ Google Mobile Ads
```

* **状態管理**: `provider` + ChangeNotifier
* **依存注入**: `MultiProvider` で簡易注入
* **データ層**: Firestore コレクション `recipes/{uid}/items`
* **広告**: リワード広告を 1 本ロード → 視聴完了で `quota += 5`

---

## 📦 環境構築 (⏱ 約5 分)

> macOS 15 + Xcode 16.4、Flutter 3.32.5（stable）想定
> **まず** `flutter doctor -v` が全項目 ✓ になることを確認してください。

```bash
# 1) 依存パッケージ取得
flutter pub get

# 2) ネイティブ依存解決
cd ios     && pod install --repo-update && cd ..
cd android && ./gradlew tasks           && cd ..

# 3) Firebase 設定ファイル（リポジトリに同梱済）
#    ios/Runner/GoogleService-Info.plist
#    android/app/google-services.json

# 4) デバッグ実行例
flutter run -d <device‑id>   # iOS / Android
flutter run -d chrome        # Web

# 5) 必須ツール（初回のみ）
dart pub global activate flutterfire_cli   # FlutterFire CLI
```

---

## 💻 開発便利コマンド

| コマンド                            | 意味 / 補足                   |
| ------------------------------- | ------------------------- |
| `flutter pub get`               | 依存取得                      |
| `flutter analyze`               | **静的解析**（lint 0 で CI 通過）  |
| `flutter test --coverage`       | ユニットテスト + カバレッジ生成         |
| `flutter run -d chrome`         | Web デバッグ + **Hot‑Reload** |
| `flutter run --release -d <id>` | 実機リリースビルド                 |
| `git pull --rebase origin main` | 最新を取得して自分の変更を先頭へ再適用       |

---

## 🗒️ ブランチ戦略 / Commit 規約

| ブランチ        | 用途                | 保護              |
| ----------- | ----------------- | --------------- |
| `main`      | リリース相当 / 常にデプロイ可能 | **保護ON** PR経由のみ |
| `feature/*` | 新機能・改修            | -               |

* **Commit メッセージプレフィックス**
  `feat:` 機能追加 | `fix:` バグ修正 | `chore:` 雑務 | `docs:` 文書変更 ...
  例）`feat: add delete button to recipe list`

---

## 📍 今後のロードマップ

*

---

## 🪪 ライセンス

Apache‑2.0
© 2025 Yuta Goto
