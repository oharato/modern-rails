class ApplicationController < ActionController::Base
  include Authentication

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Basic Authentication for staging/production protection
  before_action :authenticate_with_basic_auth, if: :basic_auth_enabled?

  private

  def basic_auth_enabled?
    ENV["BASIC_AUTH_USER"].present? && ENV["BASIC_AUTH_PASSWORD"].present?
  end

  def authenticate_with_basic_auth
    authenticate_or_request_with_http_basic("Protected Area") do |username, password|
      ActiveSupport::SecurityUtils.secure_compare(username, ENV["BASIC_AUTH_USER"]) &
        ActiveSupport::SecurityUtils.secure_compare(password, ENV["BASIC_AUTH_PASSWORD"])
    end
  end
end
