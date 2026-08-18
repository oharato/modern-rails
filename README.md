# Modern Rails 8 + Docker Compose + SQLite 3 学習用スターターキット

最新の **Ruby on Rails 8**、**SQLite 3**、**Docker Compose** を用いたモダンなフルスタックWebアプリケーション環境です。

> 📖 **インフラ構築（Pulumi）および本番デプロイ（Kamal 2）の手順は [DEPLOYMENT.md](file:///home/oharato/workspace/modern-rails/DEPLOYMENT.md) にまとめています。**

---

## 🚀 採用技術スタック & バージョン

| 技術 | バージョン | 特徴・役割 |
| :--- | :--- | :--- |
| **Ruby** | `4.0` (Slim) | 最新のRuby 4系ランタイム |
| **Ruby on Rails** | `8.0` | 最新メジャーバージョン（Solid family標準搭載） |
| **SQLite** | `3.x` | 高速・軽量な組み込みリレーショナルデータベース |
| **CSS Framework** | **Tailwind CSS v4** | `tailwindcss-rails`（Node.js不要のネイティブビルド） |
| **JavaScript** | **Importmap + Turbo 8 + Stimulus** | Node.js/npm不要のモダンフロントエンド |
| **Job Queue** | **Solid Queue** | Redis不要のDB駆動バックグラウンドキュー |
| **Cache Store** | **Solid Cache** | Redis不要のDB駆動キャッシュ |
| **WebSocket** | **Solid Cable** | Redis不要のDB駆動Action Cable |
| **Asset Pipeline** | **Propshaft** | Sprocketsに代わる高速軽量アセットパイプライン |
| **Deployment** | **Kamal 2** | コンテナベースのゼロダウンタイムデプロイ構成 |

---

## 🛠️ プロジェクト作成時に実行したコマンド一覧

以下は、このプロジェクトをゼロから構築する際に実行した一連のコマンド履歴です。

### 1. 初期設定 & Dockerビルド
```bash
# Dockerfile.dev と compose.yaml を用意した後、イメージをビルド
docker compose build web
```

### 2. Rails 8 アプリケーションの新規生成
```bash
# 最新のRails 8プロジェクトをSQLite & Tailwind CSS構成で初期化
docker compose run --rm --no-deps web bundle exec rails new . \
  --name=modern_rails \
  --force \
  --database=sqlite3 \
  --css=tailwind
```

### 3. データベース & 認証機能の導入 (Rails 8 新機能)
```bash
# DB接続設定(database.yml)調整後にデータベース作成
docker compose run --rm web bin/rails db:create

# Rails 8 組み込み認証ジェネレータの実行 (Devise等を使わない標準認証)
docker compose run --rm web bin/rails generate authentication

# プロジェクト & タスク管理モデルの作成
docker compose run --rm web bin/rails generate model Project title:string description:text user:references color:string
docker compose run --rm web bin/rails generate model Task title:string completed:boolean due_date:date priority:integer project:references user:references

# マイグレーションの実行
docker compose run --rm web bin/rails db:migrate
```

### 4. 初期シードデータの投入 & Tailwindビルド
```bash
# デモユーザーとサンプルタスクの投入
docker compose run --rm web bin/rails db:seed

# Tailwind CSSのビルド
docker compose run --rm web bin/rails tailwindcss:build
```

---

## 💻 起動方法 & 使い方

### 1. アプリケーションの起動
```bash
docker compose up
```
バックグラウンドで起動する場合:
```bash
docker compose up -d
```

### 2. ブラウザでアクセス
- URL: **`http://localhost:3000`** または **`http://nuc7.local:3000`**
*(開発環境 `development.rb` にて `config.hosts.clear` を設定済みのため、ローカルネットワーク内のホスト名やIPアドレスからアクセス可能です)*

### 3. 初期ログインアカウント
`db/seeds.rb` により以下のデモユーザーが登録されています：
- **メールアドレス**: `demo@example.com`
- **パスワード**: `password123`
*(画面右上の「新規登録」から新しいアカウントを作成することも可能です)*

---

## 🌟 Rails 8 モダンスタックの学習ポイント

### 1. 組み込み認証 (`rails generate authentication`)
- Rails 8 からフレームワーク本体に認証ジェネレータが追加されました。
- `User`, `Session`, `Current` モデルと `Authentication` concern が自動生成され、Cookieセッションによる堅牢な認証が標準で動作します。

### 2. Solid Trio (Redis不要のモダンアーキテクチャ)
- **Solid Queue**: SQLiteのテーブルを活用した非同期ジョブ実行。本アプリの「ジョブ実行テスト」画面（`/jobs/test`）で確認できます。
- **Solid Cache**: DB内にキャッシュを保持する仕組み。ダッシュボードの統計情報が `Rails.cache.fetch` で高速キャッシュされています。
- **Solid Cable**: RedisなしでAction Cable/Turbo Streamsのリアルタイム通信を実現。

### 3. Hotwire (Turbo Streams + Morphing)
- タスクの追加・完了切り替え・削除やプロジェクト作成が、**ページリロードなし（Turbo Streams）** で即座にDOM更新されます。
- `broadcasts_refreshes` による自動同期にも対応しています。

### 4. Tailwind CSS v4 + Importmap (Node.jsフリー)
- Node.jsやWebpack/Viteを介さず、StandaloneなTailwind CLIとブラウザ標準のES Modules (Importmap) で高速に動作します。

---

## 📋 よく使う開発コマンド集

| 操作 | コマンド |
| :--- | :--- |
| **コンテナ起動** | `docker compose up` |
| **コンテナ停止** | `docker compose down` |
| **Railsコンソール** | `docker compose run --rm web bin/rails console` |
| **DBマイグレーション** | `docker compose run --rm web bin/rails db:migrate` |
| **DBリセット & シード** | `docker compose run --rm web bin/rails db:reset` |
| **Tailwindビルド** | `docker compose run --rm web bin/rails tailwindcss:build` |
| **テスト実行** | `docker compose run --rm web bin/rails test` |

---

## ⚡ LSP (Language Server) の設定 (Fresh Editor / VSCode / Neovim)

本プロジェクトには、Shopify製の最新公式LSP **`ruby-lsp`** および Rails 拡張 **`ruby-lsp-rails`** が導入されています。

### 導入済みファイル
- `Gemfile`: `ruby-lsp`, `ruby-lsp-rails`
- `bin/docker-ruby-lsp`: Dockerコンテナ経由でLSPを起動する実行可能ラッパースクリプト

### Fresh Editor / エディタでの設定方法

#### 方法 A: Dockerコンテナ経由でLSPを使う場合（推奨）
ホスト側にRuby環境がなくても、用意された `bin/docker-ruby-lsp` をエディタのLSPコマンドに指定するだけで利用できます。

**Fresh Editor の設定 (`~/.config/fresh/config.json`):**
```json
{
  "lsp": {
    "ruby": [
      {
        "command": "bin/docker-ruby-lsp",
        "enabled": true,
        "auto_start": true,
        "args": [],
        "root_markers": [
          "Gemfile",
          ".ruby-version",
          ".git"
        ]
      }
    ]
  }
}
```
*(※ すでに `~/.config/fresh/config.json` に設定済みですので、そのまま `fresh` コマンドでファイルを開けば利用可能です)*

### LSPで利用できる機能
- **定義元ジャンプ (Go to Definition)**: モデル、コントローラー、ヘルパー、ActiveRecordメソッド等
- **Rails固有のナビゲーション**: ルート定義からアクションへのジャンプ、アソシエーションの解決
- **コード補完 & ホバー情報**: 型やドキュメントの即時表示
- **自動フォーマット & リント**: RuboCop とのシームレスな統合

---

## 🔍 データベース管理 (Harlequin TUI)

ターミナルベースの高速SQL IDE **[Harlequin](https://harlequin.sh/)** を使って、開発環境およびテスト環境のSQLiteデータベースを閲覧・操作できます。

プロジェクトルートに [`.harlequin.toml`](file:///home/oharato/workspace/modern-rails/.harlequin.toml) が配置されているため、追加オプション不要で接続可能です。

### 1. インストール (未導入の場合)
```bash
uv tool install "harlequin[sqlite]"
# または
uv tool install harlequin
```

### 2. 起動方法

```bash
# 開発環境 DB (storage/development.sqlite3) に接続
harlequin

# テスト環境 DB (storage/test.sqlite3) に接続
harlequin -P test
```

### 3. CLIワンライナー実行 (`hsql`)
TUIを開かずにターミナル上で直接クエリ結果を出力することも可能です。
```bash
# 開発DBでクエリ実行
hsql -c "SELECT count(*) FROM users;"

# テストDBでクエリ実行
hsql -P test -c "SELECT count(*) FROM users;"
```

### 4. 主な操作キー
| キー | 動作 |
| :--- | :--- |
| **`Ctrl + J`** / **`F5`** | カーソル位置のSQL / 選択範囲のSQLを実行 |
| **`F6`** | データカタログ（テーブル一覧・スキーマ）にフォーカス切替 |
| **`F7`** | クエリ結果ビューにフォーカス切替 |
| **`Ctrl + K`** | クエリフォーマッタ実行 |
| **`Ctrl + C`** / **`Ctrl + Q`** | Harlequin の終了 |

