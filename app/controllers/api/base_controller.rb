class Api::BaseController < ApplicationController
  skip_before_action :verify_authenticity_token
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  private

  def not_found(exception)
    render json: { error: exception.message }, status: :not_found
  end
end
