module SeoAiEngine
  class ApplicationController < ActionController::Base
    # Include host app's authentication concern
    include ::Authentication

    # Require admin access for all engine routes
    before_action :require_admin

    private

    # Ensure user is authenticated and has admin privileges
    # Uses host app's authentication system via Current.user
    def require_admin
      unless Current.user&.admin?
        redirect_to main_app.root_path, alert: "You are not authorized to access the AI SEO admin."
      end
    end
  end
end
