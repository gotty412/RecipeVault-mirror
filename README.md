# 🍳 RecipeVault

Flutter 製 **個人レシピ帳**。  
広告（リワード）視聴で保存上限を拡張できる MVP 版アプリです。

|                         | 現状 |
|-------------------------|------|
| **初期保存枠**          | 10 件 |
| **広告 1 回視聴**       | ＋5 件拡張 |
| **認証方式**            | 匿名ログイン（`firebase_auth`） |
| **バックエンド**          | Cloud Firestore |
| **広告 SDK**           | Google Mobile Ads (Rewarded) |
| **CI / CD**           | *準備中*（Bitbucket Pipelines） |

---

## 📦 環境構築 (⏱ 約 5 分)

> ⚙️ macOS 15 / Xcode 16.4  
> 🐦 Flutter 3.32.5 (stable) 想定  
> **必ず** `flutter doctor -v` がすべて ✓ になることを確認してください。

```bash
# 1) 依存パッケージ取得
flutter pub get

# 2) ネイティブ依存解決
cd ios     && pod install --repo-update && cd ..
cd android && ./gradlew tasks           && cd ..

# 3) Firebase 設定ファイル（すでに同梱済み）
#    ├─ ios/Runner/GoogleService-Info.plist
#    └─ android/app/google-services.json

# 4) デバッグ実行例
flutter run -d <device‑id>   # iOS / Android 実機
flutter run -d chrome        # Web (Chrome)
