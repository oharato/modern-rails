# ⚡ GCP e2-micro 向けRails軽量化ガイド

GCP の Always Free 枠（e2-micro / メモリ1GB）上で Rails アプリを安定稼働させるための最適化手順をまとめます。

---

## 🔍 なぜ重くなるのか？

### ① メモリ不足 → スワップ多発 → ディスクI/O詰まり

Rails は起動時（Puma + Bootsnap 等）で **200MB〜400MB以上** のメモリを消費します。
同一VM上で PostgreSQL / Redis 等を動かすと、メモリ 1GB はすぐに枯渇します。

メモリが不足すると OS は **Swap（ディスクへの退避）** を行いますが、e2-micro の標準ディスクは
**IOPS が 22〜45 程度** しかないため、ディスクI/O待ち（iowait）で CPU が 100% に張り付き、
フリーズ状態になります。

### ② CPUスロットリング

`assets:precompile` や起動時のオートロード等の重い処理で一時的に CPU を使い切ると、
e2-micro のバースト枠を使い切って **0.25コア相当に強制制限（Throttling）** されます。

---

## 🛠️ 対策一覧

### 1. Puma の設定を最小化する（実施済み）

`config/puma.rb` でワーカー数・スレッド数を最小化しています。

```ruby
# WEB_CONCURRENCY=0: クラスタモード（マルチワーカー）を無効化
# RAILS_MAX_THREADS=2: スレッド数を 2 に制限
threads_count = ENV.fetch("RAILS_MAX_THREADS", 2)
threads threads_count, threads_count

workers_count = ENV.fetch("WEB_CONCURRENCY", 0).to_i
workers workers_count if workers_count >= 1
```

環境変数で上書きする場合はデプロイ設定（`config/deploy.yml` の `env.clear`）に追記してください：

```yaml
env:
  clear:
    WEB_CONCURRENCY: 0
    RAILS_MAX_THREADS: 2
```

---

### 2. スワップ領域の作成と swappiness の調整

サーバー上で以下のコマンドを実行し、2GBのスワップファイルを作成します：

```bash
# スワップファイルの作成（2GB）
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# 再起動後も有効にする
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# スワップ頻度を下げる（0〜100: 値が低いほど RAM を優先利用）
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

---

### 3. DB を外部サービスまたは SQLite に移行する

同一 VM 内での PostgreSQL / MySQL 同居は最もメモリを圧迫する要因です。
以下のいずれかへの移行を検討してください：

| 選択肢 | 概要 |
| :--- | :--- |
| **Neon** | サーバーレス PostgreSQL（無料枠あり） |
| **Supabase** | PostgreSQL互換のBaaS（無料枠あり） |
| **SQLite** | 軽量・同一プロセス内動作・外部DBが不要 |

---

### 4. アセットプリコンパイルはローカル/CIで実行する

本番サーバー上で `assets:precompile` や `npm/yarn build` を実行すると、
メモリ不足で **OOM Killer** にプロセスが強制終了されます。

```bash
# ❌ 本番サーバーでは実行しない
# bundle exec rails assets:precompile

# ✅ ローカルまたは GitHub Actions（CI）上でビルドし、
#    コンパイル済みアセットをコンテナイメージに含める（Dockerfile参照）
```

本プロジェクトの `Dockerfile` は CI（GitHub Actions）上で `assets:precompile` を実行し、
コンパイル済みアセットをイメージに焼き込んでいるため、本番サーバーでの実行は不要です。

---

## 📊 最適化後の効果（目安）

| 項目 | 最適化前 | 最適化後 |
| :--- | :---: | :---: |
| Puma 起動時メモリ | ~350MB | ~200MB |
| スワップ発生頻度 | 高い | 低い |
| iowait（ディスクI/O待ち） | 高い | 低い |
| CPU スロットリング発生 | 頻繁 | まれ |
