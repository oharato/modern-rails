# Rails 8 Seed data
user = User.find_or_create_by!(email_address: "demo@example.com") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
end

puts "Seed user created: #{user.email_address} (password: password123)"

project1 = user.projects.find_or_create_by!(title: "Rails 8 調査・学習", color: "blue", description: "Rails 8の新機能とモダンスタックの検証")
project2 = user.projects.find_or_create_by!(title: "プロダクション移行", color: "purple", description: "Kamal 2 と Solid Queue の導入")

user.tasks.find_or_create_by!(title: "Rails 8 の組み込み認証ジェネレータを試す", project: project1, priority: :high, completed: true)
user.tasks.find_or_create_by!(title: "Solid Queue / Solid Cache の動作確認", project: project1, priority: :urgent, completed: false)
user.tasks.find_or_create_by!(title: "Tailwind CSS v4 のスタイリング確認", project: project1, priority: :medium, completed: false)
user.tasks.find_or_create_by!(title: "Hotwire Turbo Streams によるリアルタイム更新", project: project2, priority: :high, completed: false)

puts "Seed projects and tasks created successfully!"
