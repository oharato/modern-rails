# Seed script for CraftCommerce

puts "Clearing existing data..."
ActiveRecord::Base.connection.disable_referential_integrity do
  [
    Review, OrderItem, Order, ProductImage, Product, Category,
    Session, User, JobLog
  ].each(&:delete_all)

  %w[tasks projects].each do |tbl|
    ActiveRecord::Base.connection.execute("DELETE FROM #{tbl}") if ActiveRecord::Base.connection.table_exists?(tbl)
  end
end

puts "Creating Accounts..."
admin = User.create!(
  email_address: "admin@example.com",
  password: "password123",
  password_confirmation: "password123",
  name: "管理者",
  role: "admin"
)

customer = User.create!(
  email_address: "user@example.com",
  password: "password123",
  password_confirmation: "password123",
  name: "テストユーザー",
  role: "customer"
)

puts "Creating Categories..."
categories = {
  "craft-art" => Category.create!(name: "クラフト・雑貨", slug: "craft-art", description: "ハンドメイドの生活雑貨・工芸品"),
  "woodwork" => Category.create!(name: "木工家具", slug: "woodwork", description: "無垢材を使用した温もりある木工作品"),
  "ceramics" => Category.create!(name: "陶芸・ガラス", slug: "ceramics", description: "職人技が光る陶器・吹きガラスの器"),
  "leather" => Category.create!(name: "レザーアイテム", slug: "leather", description: "経年変化を楽しむ本革レザークラフト"),
  "digital" => Category.create!(name: "デジタルアート・フォント", slug: "digital", description: "クリエイター制作の高品質デジタル素材")
}

puts "Creating Products..."
products_data = [
  {
    category: categories["craft-art"],
    name: "和紙のモダン間接照明",
    slug: "washi-ambient-light",
    description: "手漉き和紙の柔らかな透過光が空間を包み込む、現代の住まいに調和するスタンドライト。調光機能付きで読書灯やベッドサイドライトに最適です。",
    price: 8800,
    stock_quantity: 5,
    is_published: true
  },
  {
    category: categories["craft-art"],
    name: "寄木細工のコースターセット (4枚組)",
    slug: "yosegi-coasters",
    description: "箱根の伝統工芸「寄木細工」の技法で作られたコースター。緻密な幾何学模様が美しく、ウレタン塗装仕上げで水滴にも強い実用的なアイテムです。",
    price: 3200,
    stock_quantity: 12,
    is_published: true
  },
  {
    category: categories["woodwork"],
    name: "楢材の無垢カッティングボード",
    slug: "oak-cutting-board",
    description: "国産の楢（オーク）無垢材から削り出された、堅牢で美しい木目のまな板。サービングボードとしても食卓を華やかに演出します。",
    price: 6500,
    stock_quantity: 4,
    is_published: true
  },
  {
    category: categories["woodwork"],
    name: "手彫りのウォールナットスツール",
    slug: "walnut-handcrafted-stool",
    description: "厳選されたブラックウォールナットを使用し、座面を体に沿うよう削り出したクラフトスツール。オイルフィニッシュ仕上げ。",
    price: 24000,
    stock_quantity: 2,
    is_published: true
  },
  {
    category: categories["ceramics"],
    name: "藍染め風 益子焼マグカップ",
    slug: "indigo-mashiko-mug",
    description: "益子焼のぽってりとした温かい土感に、藍色の釉薬が美しく映えるマグカップ。手に吸い付くような持ちやすさです。",
    price: 3800,
    stock_quantity: 8,
    is_published: true
  },
  {
    category: categories["ceramics"],
    name: "琉球ガラスの一輪挿し (青グラデーション)",
    slug: "ryukyu-glass-vase",
    description: "沖縄の海を思わせる気泡と透明感が美しい手吹き琉球ガラスの一輪挿し。光の差し込む窓辺に飾ると美しい影が落ちます。",
    price: 4500,
    stock_quantity: 0, # Out of stock demo
    is_published: true
  },
  {
    category: categories["leather"],
    name: "オイルレザーのミニマルウォレット",
    slug: "minimal-oil-leather-wallet",
    description: "イタリア産最高級プルアップレザーを使用。カード・紙幣・コインを手のひらサイズにコンパクトに収納。使い込むほどに深い色艶が増します。",
    price: 14800,
    stock_quantity: 7,
    is_published: true
  },
  {
    category: categories["digital"],
    name: "クラフト書体フォントパック (商用ライセンス)",
    slug: "craft-typography-pack",
    description: "手書きの温かみと端正な可読性を両立したOpenTypeフォントセット（3ウェイト）。Webフォント・印刷・動画テロップに商用利用可能です。",
    price: 5000,
    stock_quantity: 99,
    is_published: true
  }
]

# SVG generator helper
def generate_product_svg(title, category_name, color1, color2)
  <<~SVG
    <svg xmlns="http://www.w3.org/2000/svg" width="600" height="600" viewBox="0 0 600 600">
      <defs>
        <linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" style="stop-color:#{color1};stop-opacity:1" />
          <stop offset="100%" style="stop-color:#{color2};stop-opacity:1" />
        </linearGradient>
      </defs>
      <rect width="600" height="600" fill="url(#grad)" rx="24"/>
      <circle cx="300" cy="240" r="120" fill="white" opacity="0.15"/>
      <text x="300" y="260" font-size="72" text-anchor="middle" fill="white" opacity="0.9">✨</text>
      <text x="300" y="400" font-family="'Helvetica Neue', Arial, sans-serif" font-size="28" font-weight="bold" text-anchor="middle" fill="white">#{title}</text>
      <rect x="230" y="430" width="140" height="32" rx="16" fill="white" opacity="0.25"/>
      <text x="300" y="452" font-family="'Helvetica Neue', Arial, sans-serif" font-size="14" font-weight="600" text-anchor="middle" fill="white">#{category_name}</text>
    </svg>
  SVG
end

colors = [
  [ "#4f46e5", "#818cf8" ],
  [ "#d97706", "#f59e0b" ],
  [ "#059669", "#10b981" ],
  [ "#dc2626", "#f87171" ],
  [ "#7c3aed", "#a78bfa" ],
  [ "#2563eb", "#60a5fa" ],
  [ "#b45309", "#d97706" ],
  [ "#475569", "#64748b" ]
]

products = products_data.each_with_index.map do |data, idx|
  prod = Product.create!(data)

  # Attach SVG dummy image
  c1, c2 = colors[idx % colors.size]
  svg_content = generate_product_svg(prod.name, prod.category.name, c1, c2)
  prod.images.attach(
    io: StringIO.new(svg_content),
    filename: "#{prod.slug}.svg",
    content_type: "image/svg+xml"
  )

  prod
end

puts "Creating Reviews..."
reviews_data = [
  { product: products[0], rating: 5, comment: "和室にも洋室のリビングにも馴染む素晴らしいデザインです。夜のリラックスタイムに欠かせません。" },
  { product: products[0], rating: 4, comment: "明るさの調整が滑らかで使いやすいです。丁寧な梱包で届きました。" },
  { product: products[1], rating: 5, comment: "繊細な木工技術に感動しました。来客時に出すと必ず褒められます。" },
  { product: products[2], rating: 5, comment: "しっかりとした重みがあり、包丁の刃あたりがとても良いです。オイルでお手入れしながら長く愛用します。" },
  { product: products[3], rating: 5, comment: "座り心地が抜群で、木目の美しさに惚れ惚れします。まさに一生モノの家具です。" },
  { product: products[4], rating: 4, comment: "深みのある藍色がとても綺麗です。毎朝のコーヒーが楽しみになりました。" },
  { product: products[6], rating: 5, comment: "革の質感が非常に高く、エイジングが楽しみです。ポケットにすっきり収まります。" }
]

reviews_data.each do |r|
  Review.create!(
    user: customer,
    product: r[:product],
    rating: r[:rating],
    comment: r[:comment]
  )
end

puts "Creating Sample Initial Order & Job Logs..."
# Sample previous order for demo
sample_order = customer.orders.create!(
  order_number: "ORD-#{Time.current.strftime('%Y%m%d')}-SAMPLE",
  total_amount: 12000,
  status: "paid",
  created_at: 1.day.ago
)
sample_order.order_items.create!(
  product: products[0],
  price_at_purchase: 8800,
  quantity: 1
)
sample_order.order_items.create!(
  product: products[1],
  price_at_purchase: 3200,
  quantity: 1
)

# Generate sample receipt
ReceiptGenerationJob.perform_now(sample_order.id)

# Create initial job logs for admin visibility
JobLog.create!(
  job_type: "order_confirmation_mail",
  status: "completed",
  payload: { order_id: sample_order.id, email: customer.email_address }.to_json,
  created_at: 1.day.ago,
  finished_at: 1.day.ago + 2.seconds
)

JobLog.create!(
  job_type: "daily_sales_report",
  status: "completed",
  payload: { target_date: 1.day.ago.to_date.to_s, orders_count: 1, total_sales: 12000 }.to_json,
  created_at: 1.day.ago + 1.hour,
  finished_at: 1.day.ago + 1.hour + 3.seconds
)

puts "Clearing cache..."
Rails.cache.clear

puts "================================================="
puts "CraftCommerce Seeding Completed Successfully!"
puts "Admin Account: admin@example.com / password123"
puts "Customer Account: user@example.com / password123"
puts "Products Created: #{Product.count} items"
puts "Categories: #{Category.count}"
puts "================================================="
