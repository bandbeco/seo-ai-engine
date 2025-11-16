module SeoAiEngine
  class ApplicationController < ActionController::Base
    # Require authentication for all engine routes
    # This delegates to the host app's authentication system
    before_action :authenticate_user!

    private

    # Delegate authentication to host app's Current.user
    # Raises error if no user is logged in
    def authenticate_user!
      unless defined?(Current) && Current.respond_to?(:user) && Current.user.present?
        redirect_to main_app.root_path, alert: "You must be logged in to access this area."
      end
    end
  end
end
