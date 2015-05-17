class FrontendController < ActionController::Base
  include Authentication

  def show
    render file: Rails.root.join('frontend', 'dist', 'index.html')
  end
end
