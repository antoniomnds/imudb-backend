class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, with: :not_found


  private

  def not_found
    render json: "The resource you're looking for was not found.", status: 404
  end
end
