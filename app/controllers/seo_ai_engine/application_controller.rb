module SeoAiEngine
  class ApplicationController < ActionController::Base
    # Include host app's authentication concern
    include ::Authentication

    # Require authentication for all engine routes
    before_action :require_authentication

    private

    # Ensure user is authenticated before accessing admin features
    # Uses host app's authentication system via Current.user
    def require_authentication
      unless Current.user.present?
        redirect_to main_app.root_path, alert: "You must be logged in to access the AI SEO admin."
      end
    end
  end
end
