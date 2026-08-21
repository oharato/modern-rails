module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :set_current_session
    before_action :require_authentication
    helper_method :authenticated?, :current_user, :current_cart, :current_recently_viewed, :guest_session_id
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private

  def set_current_session
    resume_session
  end

  def authenticated?
    resume_session.present?
  end

  def current_user
    Current.user
  end

  def require_authentication
    resume_session || request_authentication
  end

  def require_admin
    unless Current.user&.admin?
      respond_to do |format|
        format.html { redirect_to root_path, alert: "管理者権限が必要です。" }
        format.json { render json: { error: "Forbidden: Admin access required" }, status: :forbidden }
      end
    end
  end

  def resume_session
    Current.session ||= find_session_by_cookie
  end

  def find_session_by_cookie
    Session.find_by(id: cookies.signed[:session_id]) if cookies.signed[:session_id]
  end

  def request_authentication
    respond_to do |format|
      format.html do
        session[:return_to_after_authenticating] = request.url
        redirect_to new_session_path, alert: "ログインしてください。"
      end
      format.json do
        render json: { error: "Unauthorized" }, status: :unauthorized
      end
    end
  end

  def after_authentication_url
    session.delete(:return_to_after_authenticating) || root_url
  end

  def guest_session_id
    if cookies[:guest_session_id].blank?
      cookies[:guest_session_id] = {
        value: SecureRandom.uuid,
        expires: 7.days.from_now,
        httponly: true,
        same_site: :lax
      }
    end
    cookies[:guest_session_id]
  end

  def current_cart
    if Current.user
      Cart.for_user(Current.user)
    else
      Cart.for_guest(guest_session_id)
    end
  end

  def current_recently_viewed
    if Current.user
      RecentlyViewed.for_user(Current.user)
    else
      RecentlyViewed.for_guest(guest_session_id)
    end
  end

  def start_new_session_for(user)
    user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
      Current.session = session
      cookies.signed.permanent[:session_id] = { value: session.id, httponly: true, same_site: :lax }

      # Auto merge guest cart to user cart
      if (guest_id = cookies[:guest_session_id])
        Cart.merge(Cart.for_guest(guest_id), Cart.for_user(user))
        cookies.delete(:guest_session_id)
      end
    end
  end

  def terminate_session
    Current.session&.destroy
    cookies.delete(:session_id)
  end
end
