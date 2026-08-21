# CraftCommerce (Rails 8 + Solid Trio Edition)

**NuxtHub (Nuxt 4 / Cloudflare) vs Modern Rails (Rails 8 / Solid Trio) 比較検証用 統合ECプラットフォーム**

最新の **Ruby on Rails 8**、**SQLite 3**、**Solid Trio (Solid Queue, Solid Cache, Solid Cable)**、**Tailwind CSS v4** をフル活用した本格的モダンECアプリケーションです。

> 📖 **詳細設計書**: [docs/craft_commerce_specification.md](file:///home/oharato/workspace/modern-rails/docs/craft_commerce_specification.md)  
> 📊 **実装振り返り・技術比較レポート**: [docs/IMPLEMENTATION_REPORT.md](file:///home/oharato/workspace/modern-rails/docs/IMPLEMENTATION_REPORT.md)  
> 🚀 **デプロイ手順書 (Kamal 2 & Pulumi)**: [DEPLOYMENT.md](file:///home/oharato/workspace/modern-rails/DEPLOYMENT.md)

---

## 🚀 採用技術スタック & アーキテクチャ

| 機能コンポーネント | ECサイトでのユースケース | Modern Rails (Rails 8) 実装 |
| :--- | :--- | :--- |
| **商品カタログ / SSR** | SEO & 超高速レンダリング | Hotwire (Turbo Drive + Morphing) |
| **商品データ & 注文** | ユーザー、商品、在庫、注文トランザクション | SQLite 3 + ActiveRecord (排他ロック `lock!`) |
| **カート & 閲覧履歴** | ゲスト/会員の高速カート保持、自動マージ | `Solid Cache` (Key-Value Store) |
| **画像 & 領収書PDF** | ギャラリー画像、購入後のPDF領収書保管 | Active Storage + `prawn` gem (Noto Sans JP) |
| **非同期処理** | 注文確認メール、PDF生成、日次集計バッチ | `Solid Queue` + Active Job (`JobLog` 記録) |
| **カタログキャッシュ** | トップ・商品一覧の60秒キャッシュ配信 | `Solid Cache` (`Rails.cache.fetch`) |
| **在庫ライブ同期** | 残り在庫数のリアルタイム更新、管理者注文速報 | `Solid Cable` + Turbo Streams |
| **認証 & 権限** | 一般顧客アカウント & 管理者 (Admin) ダッシュボード | Rails 8 組み込み認証 + Role制御 |
| **DB管理・運用** | 在庫確認、クエリチューニング、データ保守 | Harlequin TUI (`.harlequin.toml`) |
| **品質保証 & CI** | 静的解析・セキュリティ・自動テスト・Linter | Brakeman + Importmap Audit + RuboCop + Minitest |
| **デプロイ・インフラ** | 本番稼働構成 | Kamal 2 + Pulumi (GCP) |

---

## 💻 起動方法 & 使い方

### 1. アプリケーションの起動
```bash
docker compose up
```
バックグラウンド起動:
```bash
docker compose up -d
```

### 2. ブラウザでアクセス
- 顧客向けフロント: **`http://localhost:3000`** (または LAN から **`http://nuc7.local:3000`**)
- 顧客マイダッシュボード: **`http://localhost:3000/dashboard`**
- 管理者ダッシュボード: **`http://localhost:3000/admin`**
- 学習・アーキテクチャガイド: **`http://localhost:3000/guide`**

### 3. 初期検証アカウント
`db/seeds.rb` により以下のテストアカウントが作成されています：

| 権限 | Email | Password | 役割 |
| :--- | :--- | :--- | :--- |
| **管理者 (Admin)** | `admin@example.com` | `password123` | 管理画面 (`/admin`)、在庫編集、ジョブ・キャッシュ管理 |
| **一般会員 (Customer)** | `user@example.com` | `password123` | 商品購入、カート、注文履歴、領収書PDFダウンロード、レビュー投稿 |

*(※ ログイン画面にお試しワンクリックログインボタンを用意しています)*

---

## 🌟 実装されたコア機能

### 1. 高速な商品カタログ & キャッシュ (Solid Cache)
- トップページ (`/`)、商品一覧 (`/products`) は 60秒キャッシュ。
- 管理者による商品情報・在庫編集時、および管理画面 (`/admin/cache`) からのワンクリックパージで即座にキャッシュ破棄。

### 2. ショッピングカート & 閲覧履歴 (KV Store)
- **ゲスト**: Cookie `guest_session_id` (UUID) に紐づく `cart:guest_<uuid>` (TTL: 7日) で高速読み書き。
- **会員**: `cart:user_<id>` (TTL: 30日) で保持。
- **自動マージ**: ゲスト状態で商品をカートに入れたままログイン/新規登録すると、会員カートへ自動統合しゲストカートKVを削除。
- **閲覧履歴**: `recently_viewed:guest_<uuid>` / `recently_viewed:user_<id>` に直近6件を記録し画面下部に表示。

### 3. トランザクション & 排他制御 (モック決済)
- チェックアウト時に `Product.lock` による排他ロックで在庫を安全に引き当て。
- 在庫不足時はロールバックし二重購入・在庫マイナスを防止。

### 4. 非同期ジョブ & 領収書PDF (Solid Queue + Prawn)
- 注文完了時に `OrderConfirmationMailJob` と `ReceiptGenerationJob` を非同期投入。
- Prawn + `vendor/fonts/NotoSansJP.ttf` により完全な日本語レイアウトの PDF 領収書をバイナリ生成し、Active Storage に添付・保存。
- ユーザーはマイページ (`/mypage/orders`) から領収書PDFをストリーミングダウンロード可能。
- ジョブ実行状況は `JobLog` テーブルに記録され、`/admin/jobs` で監視可能。

### 5. リアルタイム在庫 & 管理者速報 (Solid Cable / Turbo Streams)
- 商品詳細画面: 他ユーザーが購入すると在庫バッジ（「残りわずか」「在庫切れ」等）がリロードなしで即時更新。
- 管理者ダッシュボード: 新規注文が入るとリアルタイムにトースト通知が表示され、直近注文テーブルの先頭に行が追加され、売上サマリーカウンターが自動インクリメント。

### 6. REST / JSON API (仕様書 Section 6 準拠)
- `/api/auth/register`, `/api/auth/login`, `/api/auth/logout`, `/api/auth/me`
- `/api/products`, `/api/products/:slug`, `/api/categories`
- `/api/products/:slug/reviews`
- `/api/cart`, `/api/cart/items`, `/api/cart/items/:id`, `/api/user/recently-viewed`
- `/api/orders`, `/api/orders/my`, `/api/orders/:id/receipt`
- `/api/admin/products`, `/api/admin/orders`, `/api/admin/jobs/daily-report`, `/api/admin/cache/purge`

---

## 🧪 テスト & CI（継続的インテグレーション）

### 🚀 Push 前のローカル CI 一括検証 (推奨)
GitHub Actions の CI パイプラインと同じ 4 つの検証ステップ（セキュリティ診断、JS監査、Linter、全テスト）をローカルで一括実行できます：

```bash
docker compose run --rm web bin/ci
```

#### 実行内容:
1. 🔍 **Brakeman**: Rails セキュリティ脆弱性の静的解析 (`bin/brakeman --no-pager`)
2. 🔒 **Importmap Audit**: JavaScript 依存パッケージの脆弱性診断 (`bin/importmap audit`)
3. 🧹 **RuboCop**: コード規約・スタイルチェック (`bin/rubocop`)
4. 🧪 **Minitest**: 単体・統合・画面スモークテスト一括実行 (`bin/rails db:test:prepare test test:system`)

---

## 📋 よく使う開発コマンド集

```bash
# Push 前のローカル CI 一括チェック (Brakeman + RuboCop + テスト)
docker compose run --rm web bin/ci

# テストスイート単体実行 (全37テスト・139アサーション)
docker compose run --rm web bin/rails test

# RuboCop によるコードスタイル自動修正
docker compose run --rm web bin/rubocop -A

# DBシードの再投入
docker compose run --rm web bin/rails db:seed

# キャッシュクリア
docker compose run --rm web bin/rails runner "Rails.cache.clear"

# Tailwind CSSのビルド
docker compose run --rm web bin/rails tailwindcss:build

# Railsコンソール
docker compose run --rm web bin/rails console

# Harlequin TUI で SQLite をグラフィカルに操作
harlequin
```
