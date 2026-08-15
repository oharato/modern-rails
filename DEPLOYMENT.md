# Modern Rails 8 インフラ構築 & Kamal デプロイメントガイド

本ドキュメントでは、**Pulumi (TypeScript)** を用いた Google Cloud (GCP) インフラの自動プロビジョニングと、**Kamal 2** を用いた Rails 8 アプリケーションのゼロダウンタイムデプロイ手順について解説します。

---

## 🏗️ 全体アーキテクチャ

```text
[開発端末 (Local)]
  ├── ① Pulumi CLI ───> Google Cloud (GCP)
  │                      ├── Compute Engine VM (Ubuntu 24.04 + Docker) [Always Free]
  │                      ├── 静的外部 IP (固定IP: 34.27.174.205)
  │                      ├── ファイアウォール (HTTP:80, HTTPS:443, SSH:22)
  │                      └── Artifact Registry (Docker イメージ置き場)
  │
  └── ② Kamal 2 CLI ───> SSH (deploy@34.27.174.205)
                          ├── Kamal-proxy (リバースプロキシ & ゼロダウンタイム切替)
                          ├── Rails 8 Web コンテナ (Puma + Solid Queue)
                          └── PostgreSQL 17 コンテナ (Accessory DB)
```

---

## 🚀 1. Pulumi によるインフラ管理 (`infra/`)

### プロビジョニング済みリソース情報

| リソース | 名称 / 値 | 役割 |
| :--- | :--- | :--- |
| **GCP プロジェクト** | `modern-rails-1786791154` | アプリ専用プロジェクト |
| **サーバー名** | `modern-rails-server` | Compute Engine インスタンス (`e2-micro`) |
| **外部 IP アドレス** | **`34.27.174.205`** | 固定パブリック IP |
| **SSH 接続コマンド** | `ssh -i ~/.ssh/id_ed25519 deploy@34.27.174.205` | デプロイユーザー接続 |
| **Docker レジストリ** | `us-central1-docker.pkg.dev/modern-rails-1786791154/modern-rails-repo/app` | プライベートコンテナ保管庫 |

---

### Pulumi の基本操作コマンド

インフラの変更や確認は `infra/` ディレクトリ配下で実行します。

```bash
# 環境変数の準備
export PATH="$HOME/.pulumi/bin:$PATH"
export PULUMI_CONFIG_PASSPHRASE="modern-rails-passphrase"
cd infra

# 1. 計画の確認 (Dry-run)
pulumi preview

# 2. インフラの適用 (リソース作成・更新)
pulumi up

# 3. 現在のスタック出力 (IPアドレス等の確認)
pulumi stack output

# 4. インフラの完全削除 (検証終了時)
pulumi destroy
```

---

## 🚢 2. Kamal 2 による本番デプロイ手順

### (1) シークレットの設定 (`.kamal/secrets`)

デプロイに必要な秘密情報を設定します。

```bash
# .kamal/secrets ファイルを編集
RAILS_MASTER_KEY=$(cat config/master.key)
MODERN_RAILS_DATABASE_PASSWORD="your-strong-db-password"
POSTGRES_PASSWORD="your-strong-db-password"
KAMAL_REGISTRY_PASSWORD="your-docker-registry-token-or-password"
```

### (2) 初回セットアップ & デプロイ

サーバーの Docker 設定、PostgreSQL コンテナの起動、SSL プロキシのセットアップ、Rails の初期デプロイを一撃で実行します。

```bash
# 初回セットアップコマンド
bin/kamal setup
```

### (3) 2回目以降の通常デプロイ

コードを変更した後のゼロダウンタイムデプロイ：

```bash
bin/kamal deploy
```

---

## 🛠️ 3. 本番運用の便利コマンド集 (Kamal Aliases)

| 操作 | コマンド | 説明 |
| :--- | :--- | :--- |
| **本番ログ確認** | `bin/kamal logs` | Web コンテナのリアルタイムログを tail |
| **本番 Rails コンソール** | `bin/kamal console` | 本番サーバー上で `rails c` をインタラクティブ実行 |
| **本番 DB コンソール** | `bin/kamal dbc` | 本番 PostgreSQL に直接接続 |
| **本番コンテナのシェル** | `bin/kamal shell` | 本番コンテナ内に入ってデバッグ |
| **再起動** | `bin/kamal app restart` | コンテナをゼロダウンタイム再起動 |
| **DB バックアップ/復元** | `bin/kamal accessory reboot db` | DB コンテナの再起動 |

---

## 🧹 4. 後片付け（課金防止・リソースの削除）

動作確認が終了し、クラウド上のリソースをすべて削除したい場合は以下の手順を実行します：

```bash
# 1. Pulumi で作成した VM / IP / ファイアウォール等の完全削除
cd infra
export PATH="$HOME/.pulumi/bin:$PATH"
export PULUMI_CONFIG_PASSPHRASE="modern-rails-passphrase"
pulumi destroy --yes

# 2. (任意) GCP プロジェクト自体の完全削除
gcloud projects delete modern-rails-1786791154 --quiet
```
