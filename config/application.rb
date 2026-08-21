require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module ModernRails
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Active Storage proxy routes and inline svg
    config.active_storage.resolve_model_to_route = :rails_storage_proxy
    config.active_storage.content_types_to_serve_as_binary -= ["image/svg+xml"]
    config.active_storage.content_types_allowed_inline << "image/svg+xml"
  end
end
