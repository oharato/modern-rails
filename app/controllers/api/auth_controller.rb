class Api::AuthController < Api::BaseController
  allow_unauthenticated_access only: %i[register login]

  def register
    user = User.new(user_params)
    if user.save
      start_new_session_for user
      render json: { status: "success", user: user_response(user) }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def login
    email = params[:email] || params[:email_address]
    user = User.authenticate_by(email_address: email, password: params[:password])
    if user
      start_new_session_for user
      render json: { status: "success", user: user_response(user) }
    else
      render json: { error: "Invalid email or password" }, status: :unauthorized
    end
  end

  def logout
    terminate_session
    render json: { status: "success", message: "Logged out" }
  end

  def me
    if current_user
      render json: { user: user_response(current_user) }
    else
      render json: { user: nil }
    end
  end

  private

  def user_params
    p = params.permit(:email, :email_address, :password, :password_confirmation, :name)
    p[:email_address] = p.delete(:email) if p.key?(:email)
    p
  end

  def user_response(user)
    {
      id: user.id,
      email: user.email_address,
      name: user.name,
      role: user.role
    }
  end
end
