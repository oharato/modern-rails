# Modern Rails 8 インフラ構築 & Kamal デプロイメント完全手順書

本ドキュメントでは、**Google Cloud (GCP)** 上でのインフラ構築（**Pulumi**）から、**Kamal 2** によるゼロダウンタイムデプロイ、データベースのバックアップまで、**実際に実行したすべてのコマンドを漏れなく網羅** しています。

---

## 🏗️ 全体アーキテクチャ

```text
[開発端末 (Local)]
  ├── ① gcloud / Pulumi CLI ───> Google Cloud (GCP)
  │                                ├── Compute Engine VM (Ubuntu 24.04 + Docker) [Always Free: e2-micro]
  │                                ├── 静的外部 IP (固定IP: 34.27.174.205)
  │                                ├── ファイアウォール (HTTP:80, HTTPS:443, SSH:22)
  │                                └── Artifact Registry (Docker イメージリポジトリ)
  │
  └── ② Kamal 2 CLI ────────────> SSH (deploy@34.27.174.205)
                                  ├── Kamal-proxy (リバースプロキシ & ゼロダウンタイム切替)
                                  ├── Rails 8 Web コンテナ (Puma + Solid Queue + Solid Cache)
                                  └── PostgreSQL 17 コンテナ (Accessory DB / データ永続化)
```

---

## 📋 ゼロから構築する完全実行コマンド一覧

### STEP 1: GCP プロジェクト作成 & 請求先アカウントの紐付け

```bash
# 1. 一意のプロジェクトIDを生成してプロジェクト作成
PROJECT_ID="modern-rails-$(date +%s)"
gcloud projects create "$PROJECT_ID" --name="modern-rails"

# 2. 請求先アカウント（Billing Account）の紐付け
BILLING_ACCOUNT_ID=$(gcloud billing accounts list --format="value(name)" --filter="open=true" | head -n 1)
gcloud billing projects link "$PROJECT_ID" --billing-account="$BILLING_ACCOUNT_ID"

# 3. 現在のプロジェクトとして設定
gcloud config set project "$PROJECT_ID"

# 4. Compute Engine & Artifact Registry API の有効化
gcloud services enable compute.googleapis.com artifactregistry.googleapis.com
```

---

### STEP 2: デプロイ用 SSH 鍵の生成

```bash
# デプロイ専用の ed25519 鍵を生成（パスフレーズなし）
mkdir -p ~/.ssh
[ ! -f ~/.ssh/id_ed25519 ] && ssh-keygen -t ed25519 -N "" -f ~/.ssh/id_ed25519 -C "kamal@modern-rails"
```

---

### STEP 3: Pulumi によるインフラ自動プロビジョニング

```bash
# 1. Pulumi CLI のインストール（未インストールの場合）
curl -fsSL https://get.pulumi.com | sh
export PATH="$HOME/.pulumi/bin:$PATH"

# 2. infra ディレクトリで npm パッケージをインストール
cd infra
npm install

# 3. Pulumi のローカルバックエンド初期化（クラウド登録不要・無料）
export PULUMI_CONFIG_PASSPHRASE="modern-rails-passphrase"
pulumi login --local
pulumi stack select dev --create

# 4. GCP 設定をスタックに登録
pulumi config set gcp:project "$PROJECT_ID"
pulumi config set gcp:region us-central1
pulumi config set gcp:zone us-central1-a
pulumi config set modern-rails-infra:machineType e2-micro # Always Free 対象

# 5. プロビジョニング計画の確認 & 適用
pulumi preview
pulumi up --yes

# 6. 生成されたサーバーIP等の確認
pulumi stack output
cd ..
```

---

### STEP 4: サーバー側の事前ディレクトリ & 権限の準備

PostgreSQL コンテナがデータを永続化するためのディレクトリを `deploy` ユーザー権限で作成します。

```bash
# Pulumi の出力からサーバーIPを取得（または pulumi stack output で確認）
SERVER_IP=$(cd infra && export PULUMI_CONFIG_PASSPHRASE="modern-rails-passphrase" && pulumi stack output serverIp)

# SSH 経由でディレクトリ作成 & パーミッション設定
ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_ed25519 deploy@${SERVER_IP} \
  "mkdir -p /home/deploy/postgres-data && chmod 700 /home/deploy/postgres-data"
```

---

### STEP 5: Kamal 認証情報・シークレットの設定

プロジェクトルートの `.env`（または `.kamal/secrets`）に Docker Hub と Rails の機密情報を設定します。

```bash
# .env ファイルの作成
cat << 'EOF' > .env
# Docker Hub アカウント情報
DOCKER_USERNAME="your-dockerhub-username"
KAMAL_REGISTRY_PASSWORD="dckr_pat_your_dockerhub_token_or_password"

# Rails & データベース秘密鍵
RAILS_MASTER_KEY="your-rails-master-key-from-config-master-key"
POSTGRES_PASSWORD="modern_rails_production_password_2026"
MODERN_RAILS_DATABASE_PASSWORD="modern_rails_production_password_2026"
EOF
```

---

### STEP 6: Kamal による初回セットアップ & デプロイ

```bash
# 初回サーバーセットアップ & コンテナ起動（Docker、PostgreSQL、SSLプロキシ、Rails）
bin/kamal setup
```

以降、コードを変更した際の更新デプロイ：
```bash
# 通常のゼロダウンタイムデプロイ
bin/kamal deploy
```

---

## 🛠️ 運用・管理コマンドリファレンス

| 操作 | コマンド | 説明 |
| :--- | :--- | :--- |
| **本番ログ確認** | `bin/kamal logs` | Rails コンテナのログをリアルタイム tail |
| **本番 Rails コンソール** | `bin/kamal console` | 本番環境上で `rails c` をインタラクティブ実行 |
| **本番 DB コンソール** | `bin/kamal dbc` | 本番 PostgreSQL に直接接続して SQL 実行 |
| **本番コンテナのシェル** | `bin/kamal shell` | 本番コンテナ内に入ってデバッグ |
| **アプリ再起動** | `bin/kamal app restart` | コンテナをゼロダウンタイム再起動 |
| **DB バックアップ取得** | `docker compose run --rm web bin/rails db:backup:remote` | 本番 DB のダンプをローカル `./backups/` に保存 |
| **ローカル DB への復元** | `docker compose run --rm web bin/rails db:backup:restore_local` | 取得した本番ダンプをローカル開発環境に復元 |

---

## 💾 データベースのバックアップ & リストア詳細

### (1) 本番 DB のバックアップをローカルにダウンロード

```bash
# 【推奨】Rake タスクで一発取得 (./backups/production_YYYYMMDD_HHMMSS.dump に保存)
docker compose run --rm web bin/rails db:backup:remote

# または Kamal コマンドで直接実行 (PostgreSQL カスタム圧縮形式)
bin/kamal accessory exec db -- "pg_dump -U postgres -Fc modern_rails_production" > "backup_$(date +%Y%m%d_%H%M%S).dump"
```

> **💡 `-Fc` (Custom Format) のメリット:**
> - 自動で高圧縮がかかり、ファイルサイズが数分の一になります。
> - `pg_restore` によるテーブルごとの部分復元や、並行リストア（`-j 4`）に対応します。

### (2) 取得した本番データをローカル開発 DB にリストア（検証・再現用）

```bash
# ./backups/ 内の最新のバックアップファイルをローカル DB に適用
docker compose run --rm web bin/rails db:backup:restore_local
```

---

## ⚡ 7. GitHub Actions による main マージ時自動デプロイ（高速化運用）

GitHub の `main` ブランチに Pull Request がマージされると、**GitHub Actions が自動でビルド＆ゼロダウンタイムデプロイ（`--skip-prune` 高速モード）** を実行します。

### (1) GitHub Repository Secrets の登録（たった 1 個で OK！）

秘密情報はすべて Rails 標準の暗号化機能（`config/credentials.yml.enc`）で安全に暗号化されているため、GitHub の **Settings > Secrets and variables > Actions > New repository secret** に登録するのは **`RAILS_MASTER_KEY` の 1 つだけ** です！

| Secret 名 | 設定する値 / 取得方法 | 必須 |
| :--- | :--- | :---: |
| **`RAILS_MASTER_KEY`** | `cat config/master.key` の出力 | **必須（これ 1 個だけ！）** |

> **💡 The Rails Way:**
> SSH 秘密鍵、GCP サービスアカウントキー、DB パスワード等はすべて Rails Credentials 内に暗号化保存されており、CI 実行時に `RAILS_MASTER_KEY` を使って自動復号されます。

---

### (2) ワークフローの仕組み（高速化の工夫）

1. **GCP Artifact Registry（`us-central1`）による超高速イメージ転送**:
   - 同一リージョン内でのイメージ pull により、Docker Hub 経由と比べて転送時間が **約 25 秒短縮** されます。
2. **BuildKit キャッシュマウント**:
   - `Dockerfile` に `--mount=type=cache` が組み込まれており、Gemfile やアセットに変更がない場合は数秒でビルドが完了します。
2. **`--skip-prune` 高速デプロイ**:
   - 毎回のデプロイ時に古いイメージの掃除処理（10〜15秒）をスキップし、待ち時間を最小化します。
3. **週次自動クリーンアップ（`.github/workflows/cleanup.yml`）**:
   - 毎週日曜日 13:00 JST に自動で `kamal prune --all` が実行され、サーバーのディスク容量（30GB SSD）を健全に保ちます。

---

## 🔐 8. 秘匿情報（Credentials）の追加・編集・削除手順

新しい API キーや外部連携トークンを追加したい場合、**GitHub の画面で Secret を追加する必要は一切ありません**。Rails の標準コマンドを使ってローカルで安全に追加・削除できます。

### (1) 現在の秘匿情報を確認（復号して表示）

```bash
docker compose run --rm web bin/rails runner 'puts Rails.application.credentials.config.to_yaml'
```

---

### (2) 秘匿情報を編集・追加・削除する

お好みのエディタ（`nano`, `vim`, `code` 等）を指定して暗号化ファイルを直接編集します：

```bash
# 1. Credentials 編集モードを起動（一時ファイルが復号されてエディタが開きます）
EDITOR="nano" docker compose run --rm -it web bin/rails credentials:edit
```

エディタ内で YAML 形式で自由にキーを追加・修正・削除して保存終了します：

```yaml
# 例: 外部 API キーを追加する場合
secret_key_base: "..."
ssh_private_key: |
  -----BEGIN OPENSSH PRIVATE KEY-----
  ...
gcp_sa_key_base64: "..."
postgres_password: "modern_rails_production_password_2026"
basic_auth_user: "admin"
basic_auth_password: "..."

# 新しく追加した秘匿情報
stripe_api_key: "sk_live_1234567890"
openai_api_key: "sk-proj-abcdef..."
```

保存してエディタを閉じると、**自動的に AES-256-GCM で再暗号化** されて `config/credentials.yml.enc` に保存されます。

---

### (3) 新しい秘匿情報を Kamal / 本番コンテナに渡す設定

新しいキーを本番アプリや Kamal に渡したい場合は、以下の 2 ファイルに追記します：

#### 1. [`.kamal/secrets`](file:///home/oharato/workspace/modern-rails/.kamal/secrets) にマッピングを追記
```bash
# 例: STRIPE_API_KEY を Rails Credentials から抽出
STRIPE_API_KEY=$(bin/rails runner 'puts Rails.application.credentials.stripe_api_key')
```

#### 2. [`config/deploy.yml`](file:///home/oharato/workspace/modern-rails/config/deploy.yml) の `env.secret` に追記
```yaml
env:
  secret:
    - RAILS_MASTER_KEY
    - STRIPE_API_KEY
```

#### 3. Git コミットして push するだけ！
```bash
git add config/credentials.yml.enc .kamal/secrets config/deploy.yml
git commit -m "feat: add Stripe API key to encrypted credentials"
git push origin main
```
> **🎉 これだけで GitHub Actions が `RAILS_MASTER_KEY` を使って自動復号し、本番コンテナに安全に反映されます！**

---

## 🧹 リソースの完全破棄（課金防止・後片付け）

検証が完了し、クラウド上のリソースをすべて削除したい場合は以下の手順を実行します：

```bash
# 1. Pulumi で作成した VM / IP / ファイアウォール等の完全削除
cd infra
export PATH="$HOME/.pulumi/bin:$PATH"
export PULUMI_CONFIG_PASSPHRASE="modern-rails-passphrase"
pulumi destroy --yes
cd ..

# 2. (任意) GCP プロジェクト自体の完全削除
gcloud projects delete modern-rails-1786791154 --quiet
```
