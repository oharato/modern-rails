namespace :db do
  namespace :backup do
    desc "Download a compressed PostgreSQL dump from production server via Kamal to ./backups/"
    task :remote do
      timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
      backup_dir = Rails.root.join("backups")
      FileUtils.mkdir_p(backup_dir)
      backup_file = backup_dir.join("production_#{timestamp}.dump")

      puts "📦 Starting production database dump via Kamal..."
      cmd = %(bin/kamal accessory exec db -- "pg_dump -U postgres -Fc modern_rails_production" > "#{backup_file}")
      
      if system(cmd)
        puts "✅ Backup completed successfully!"
        puts "📁 Saved to: #{backup_file} (#{File.size(backup_file) / 1024} KB)"
      else
        puts "❌ Backup failed. Please ensure bin/kamal is configured and the DB accessory is running."
      end
    end

    desc "Restore the latest downloaded production backup to local development DB"
    task :restore_local do
      backup_dir = Rails.root.join("backups")
      latest_dump = Dir.glob(backup_dir.join("*.dump")).max_by { |f| File.mtime(f) }

      if latest_dump.nil?
        puts "❌ No backup files found in #{backup_dir}"
        exit 1
      end

      puts "🔄 Restoring #{File.basename(latest_dump)} into local development database..."
      db_config = Rails.configuration.database_configuration["development"]
      
      cmd = %(docker compose exec -T db pg_restore -U postgres -d modern_rails_development --clean --no-owner < "#{latest_dump}")
      if system(cmd)
        puts "✅ Local database restored successfully from production dump!"
      else
        puts "❌ Restore failed."
      end
    end
  end
end
