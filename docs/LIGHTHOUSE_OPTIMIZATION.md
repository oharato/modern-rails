# Lighthouse 監査 & Web パフォーマンス最適化レポート

本ドキュメントは、**CraftCommerce (Rails 8 Edition)** における本番環境（[`https://modern-rails.ohchans.com/`](https://modern-rails.ohchans.com/)）の Lighthouse Web サイト品質監査、および実施したパフォーマンス・アクセシビリティ・SEO 最適化の全貌をまとめた技術資料です。

---

## 📊 最適化の成果（改善前後のスコア比較）

### 🖥️ デスクトップ環境 (Desktop)

| 評価カテゴリ | 改善前 | 改善後 | 改善幅 | 状態 |
| :--- | :---: | :---: | :---: | :---: |
| ⚡️ **Performance** | 94 点 | **98 点** | 🟢 +4 点 | **超高速** |
| ♿️ **Accessibility** | 70 点 | **100 点** | 🚀 **+30 点** | **満点達成 (Perfect)** |
| 🔍 **SEO** | 92 点 | **100 点** | 🚀 **+8 点** | **満点達成 (Perfect)** |
| 🛡️ **Best Practices** | 77 点 | **77 点** | 良好 | 良好 (※後述のエッジ要因) |

---

### 📱 モバイル環境 (Mobile)

| 評価カテゴリ | 改善前 | 改善後 | 改善幅 | 状態 |
| :--- | :---: | :---: | :---: | :---: |
| ♿️ **Accessibility** | 62 点 | **100 点** | 🚀 **+38 点** | **満点達成 (Perfect)** |
| 🔍 **SEO** | 92 点 | **100 点** | 🚀 **+8 点** | **満点達成 (Perfect)** |
| ⚡️ **Performance** | 88 点 | **80〜90 点** | 安定 | 良好 |
| 🛡️ **Best Practices** | 77 点 | **77 点** | 良好 | 良好 (※後述のエッジ要因) |

---

## 📈 Core Web Vitals 指標の実測値

- **CLS (Cumulative Layout Shift / 視覚的安定性)**: **`0`** 🟢 (満点・ズレゼロ)
- **TBT (Total Blocking Time / JS応答遅延)**: **`30〜40 ms`** 🟢 (Hotwire/Turbo による極低遅延)
- **FCP (First Contentful Paint / 初回描画)**: **`0.8 秒` (Desktop)** / **`2.5 秒` (Mobile)** 🟢
- **LCP (Largest Contentful Paint / 最大描画)**: **`0.9 秒` (Desktop)** / **`2.5 秒` (Mobile)** 🟢

---

## 🛠️ 実施した具体的な最適化施策

### 1. ♿️ Accessibility (アクセシビリティ: 62点 ➜ 100点 満点)
- **HTML 言語属性 (`[html-has-lang]`)**:
  - 全レイアウト（`application.html.erb`, `admin.html.erb`）の `<html>` タグに `lang="ja"` を指定し、スクリーンリーダーやブラウザの自動翻訳に最適化。
- **ARIA ラベルの完備 (`[button-name]`, `[link-name]`)**:
  - 商品一覧のカート追加ボタンに `aria-label="#{product.name}をカートに追加"` を付与。
  - ヘッダーのショッピングカートバッジに `aria-label="ショッピングカート (X点)"` を付与。
- **WCAG AA コントラスト比適合 (`[color-contrast]`)**:
  - サブタイトルや注記テキストを `text-slate-400` から `text-slate-600` / `text-slate-500` に引き上げ。
  - レビューの星評価カラーを `text-amber-500` から `text-amber-700` に調整し、白背景に対して 4.5:1 以上のコントラスト比を達成。

### 2. 🔍 SEO (検索エンジン最適化: 92点 ➜ 100点 満点)
- **メタデスクリプション (`[meta-description]`)**:
  - 検索エンジン向けにサイト概要を説明する `<meta name="description">` を追加。
- **モバイルテーマカラー (`[theme-color]`)**:
  - モバイルブラウザのアドレスバー用 `<meta name="theme-color" content="#4f46e5">` を追加。

### 3. ⚡️ Performance (パフォーマンス: 98点達成)
- **Active Storage の N+1 クエリ解消**:
  - カタログトップ（`CatalogController`）および商品一覧（`ProductsController`）のクエリに `.with_attached_images` を追加し、添付画像テーブル（`active_storage_attachments`, `active_storage_blobs`）への N+1 発行を完全に撲滅。
- **画像の非同期デコード & 寸法明示**:
  - `ApplicationHelper#product_image_tag` に `loading="lazy"`, `decoding="async"`, `width="400"`, `height="400"` を付与。
- **Google Fonts の非同期・非ブロッキング読み込み**:
  - `media="print" onload="this.media='all'"` パターンを採用し、フォント読み込みによるレンダリングブロック（FCP 遅延）を解消。
- **HTTP Edge Cache ヘッダー**:
  - 非認証ユーザーのカタログアクセスに `Cache-Control: public, max-age=60` を付与し、TTFB（サーバー応答時間）を高速化。
- **CSP (Content Security Policy) の有効化**:
  - `config/initializers/content_security_policy.rb` を整備。

---

## 🔍 Best Practices (77点) の減点内訳について

Lighthouse の監査レポートを詳細解析した結果、減点理由はアプリケーション本体ではなく、**Cloudflare のエッジプロキシ設定および Basic 認証ヘッダー**に起因するものです：

1. **Cloudflare ボット保護スクリプト (`/cdn-cgi/challenge-platform/...`)**:
   - Cloudflare が自動挿入するスクリプトが使用している Chrome 非推奨 API の警告。
2. **Cloudflare Web Analytics (Beacon) の CORS 制限**:
   - サイト保護用の Basic 認証ヘッダーを付与して監査ツールを実行する際、サードパーティ（Cloudflare）の beacon リクエストにもヘッダーが付与され、Cloudflare 側で CORS 制限に引っかかるため。

> 💡 **補足**: 本番一般公開時に Basic 認証を解除すれば、Best Practices も 95〜100 点に到達します。

---

## 🧪 ローカルでの Lighthouse 測定手順

```bash
# 1. Chromium パスを指定して Lighthouse を実行
CHROME_PATH=/snap/bin/chromium npx -y lighthouse "https://modern-rails.ohchans.com/" \
  --preset=desktop \
  --no-enable-error-reporting \
  --extra-headers '{"Authorization": "Basic <BASE64_AUTH>"}' \
  --chrome-flags="--headless=new --no-sandbox --disable-gpu --disable-dev-shm-usage" \
  --output html --output-path ./lighthouse_report.html
```
