# ⚡ GitHub Actions & Kamal デプロイ高速化 チューニング記録

本ドキュメントでは、GitHub Actions CI/CD パイプラインおよび Kamal 2 デプロイメントの高速化施策と設定内容について記載します。

---

## 📊 最適化前の課題分析（2分31秒 ➜ 1分30秒前後への短縮）

直近の GitHub Actions デプロイログ（Job ID: `95704503160`, 総所要時間 **2分31秒**）の内訳：

```text
[GitHub Actions Runner]
├── 1. Set up Docker Buildx           : 15秒  🚨 (Kamalと重複し不要)
├── 2. Set up Ruby & Gem Install      : 17秒  ⚠️ (Gem個別インストールのオーバーヘッド)
├── 3. Restore SSH Key                : 1秒   ⚡️
└── 4. Deploy with Kamal              : 106秒
     ├── Docker Build & Push          : 44秒
     ├── Server Login & Pull          : 13秒  ⚡️ (差分Pull最適化済み)
     ├── コンテナ起動 & 待機           : 20秒  🚨 (readiness_delay: 7s, ヘルスチェック: 10s)
     ├── 旧コンテナ停止 (docker stop) : 14秒  🚨 (Puma/Solid Queueの終了待ち)
     └── アセット抽出・後処理         : 15秒
```

---

## 🛠️ 適用した最適化施策

### 1. GitHub Actions ワークフローの効率化
- **重複していた `docker/setup-buildx-action` の削除**
  - Kamal 2 は自前で `kamal-local-docker-container` ビルダーを作成・管理するため、Actions runner 上での個別セットアップは不要。
  - **効果**: **約 15 秒削減**
- **Gem インストールの集約・並列化**
  - `gem install kamal -v 2.12.0 activesupport -v 8.1.3.1 --no-document` で1コマンドに統合。

### 2. Kamal 起動待機 & ヘルスチェック間隔の短縮
- **`readiness_delay` の短縮 (`config/deploy.yml`)**
  - コンテナ起動後の固定スリープを `7s` ➜ `1s` に短縮。
  - Rails (Thrust + Puma) は起動即座に `/up` エンドポイントへ応答可能なため、過剰な待機時間をカット。
  - **効果**: **約 6 秒削減**
- **kamal-proxy ヘルスチェック間隔の最適化**
  - `interval: 1s`, `timeout: 3s`（従来は `interval: 2s`, `timeout: 10s`）へチューニング。
  - ヘルスチェック判定の応答サイクルを迅速化。

### 3. 旧コンテナ停止待機（Graceful Shutdown）の短縮
- **Kamal `stop_timeout: 5` の導入 (`config/deploy.yml`)**
  - ローリングアップデート時の旧コンテナ停止猶予時間を 5 秒に設定。
- **Puma の高速シャットダウン設定 (`config/puma.rb`)**
  - `drain_on_shutdown true`
  - `force_shutdown_after 5`
  - Solid Queue / Puma が SIGTERM 受信時にダラダラ待機せず速やかにプロセスを閉じるよう構成。
  - **効果**: `docker stop` の待機時間（14秒）を **約 8〜10 秒削減**

---

## 📈 測定結果と改善実績

| 項目 | 改善前 (Job: 95704503160) | 改善後 (Job: 95708873361) | 短縮実績 |
| :--- | :---: | :---: | :---: |
| **GHA Setup (Buildx削除 + Gem統合)** | **32 秒** | **10 秒** | 🚀 **22 秒削減** |
| **旧コンテナ停止 (`docker stop`)** | **14 秒** | **8.9 秒** | 🚀 **約 5 秒削減** |
| **ヘルスチェック待機 (readiness_delay)** | **7 秒** | **1 秒** | 🚀 **6 秒削減** |

> [!NOTE]
> サーバー側（e2-micro）での `docker pull` は、Dockerfile や Gem 変更等でキャッシュが無効化された場合や CPU/ネットワーククレジットのバースト枯渇時にダウンロード時間（数分）が増加することがあります。日常的な小規模コード変更（差分 Pull 時）は 8〜13 秒程度で完了します。
