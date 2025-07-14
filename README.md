# 🍳 RecipeVault

Flutter 製 **個人レシピ帳**  
広告（リワード）視聴で “保存上限” を拡張できる MVP 版アプリです。

|               | 現状 |
|---------------|------|
| **初期保存枠** | 10 件 |
| **広告 1 回視聴** | +5 件拡張 |
| **認証方式** | 匿名ログイン（`firebase_auth`） |
| **バックエンド** | Cloud Firestore |
| **広告** | Google Mobile Ads（リワード） |
| **CI** | ―（今後 GitHub / Bitbucket Pipelines で追加予定） |

---

## 📦 環境構築

```bash
# 1) 依存パッケージ取得
flutter pub get

# 2) iOS/Android ネイティブ依存解決
cd ios   && pod install --repo-update && cd ..
cd android && ./gradlew tasks && cd ..

# 3) Firebase 設定ファイル
#    * Android → android/app/google-services.json
#    * iOS     → ios/Runner/GoogleService-Info.plist
#    すでに配置済み

# 4) 実機でデバッグ実行（例: iOS）
flutter run -d <device-id>
