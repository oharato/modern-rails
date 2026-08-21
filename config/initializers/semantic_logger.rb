# Configure Rails Semantic Logger
return unless defined?(SemanticLogger)

if Rails.env.development?
  # Clear default appenders to have full control
  SemanticLogger.clear_appenders!

  # 1. Output colored text to STDOUT for human-friendly terminal logs
  SemanticLogger.add_appender(io: $stdout, formatter: :color)

  # 2. Output structured JSON to log/development.json.log
  SemanticLogger.add_appender(
    file_name: Rails.root.join("log/#{Rails.env}.json.log").to_s,
    formatter: :json
  )
end
