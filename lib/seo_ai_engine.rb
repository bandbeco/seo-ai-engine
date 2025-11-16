require "seo_ai_engine/version"
require "seo_ai_engine/engine"

module SeoAiEngine
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration
    attr_accessor :llm_provider,
                  :strategist_model,
                  :writer_model,
                  :reviewer_model,
                  :anthropic_api_key,
                  :google_oauth_client_id,
                  :google_oauth_client_secret,
                  :google_oauth_refresh_token,
                  :serpapi_key,
                  :serpapi_daily_limit,
                  :max_drafts_per_week,
                  :claude_timeout,
                  :max_retries

    def initialize
      @llm_provider = :anthropic
      @strategist_model = "claude-sonnet-4"
      @writer_model = "claude-sonnet-4"
      @reviewer_model = "claude-haiku-4"
      @serpapi_daily_limit = 3
      @max_drafts_per_week = 10
      @claude_timeout = 120  # seconds
      @max_retries = 3
    end
  end
end
