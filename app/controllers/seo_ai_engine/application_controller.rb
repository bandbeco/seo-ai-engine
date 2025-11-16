module SeoAiEngine
  class ApplicationController < ActionController::Base
    # Engine inherits layout and authentication from host app
    # Admin controllers should add authentication check before_action
  end
end
