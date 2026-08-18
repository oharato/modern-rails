namespace :db do
  namespace :backup do
    desc "Download production SQLite database via Kamal to ./backups/"
    task :remote do
      timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
      backup_dir = Rails.root.join("backups")
      FileUtils.mkdir_p(backup_dir)
      backup_file = backup_dir.join("production_#{timestamp}.sqlite3")

      puts "📦 Starting production database backup via Kamal..."
      cmd = %(bin/kamal app exec -- "cat storage/production.sqlite3" > "#{backup_file}")

      if system(cmd) && File.size?(backup_file)
        puts "✅ Backup completed successfully!"
        puts "📁 Saved to: #{backup_file} (#{File.size(backup_file) / 1024} KB)"
      else
        puts "❌ Backup failed. Please ensure bin/kamal is configured and the app container is running."
      end
    end

    desc "Restore the latest downloaded production backup to local development DB"
    task :restore_local do
      backup_dir = Rails.root.join("backups")
      latest_dump = Dir.glob(backup_dir.join("*.sqlite3")).max_by { |f| File.mtime(f) }

      if latest_dump.nil?
        puts "❌ No backup files found in #{backup_dir}"
        exit 1
      end

      puts "🔄 Restoring #{File.basename(latest_dump)} into local development database (storage/development.sqlite3)..."
      FileUtils.mkdir_p(Rails.root.join("storage"))
      FileUtils.cp(latest_dump, Rails.root.join("storage/development.sqlite3"))
      puts "✅ Local database restored successfully from production dump!"
    end
  end
end
