require "seo_ai_engine/version"
require "seo_ai_engine/engine"
require "ruby_llm"

module SeoAiEngine
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  class Configuration
    attr_accessor :strategist_model,
                  :writer_model,
                  :reviewer_model,
                  :google_service_account,
                  :serpapi_key,
                  :serpapi_daily_limit,
                  :max_drafts_per_week,
                  :llm_timeout,
                  :max_retries

    def initialize
      @strategist_model = "claude-sonnet-4"
      @writer_model = "claude-sonnet-4"
      @reviewer_model = "claude-haiku-4"
      @serpapi_daily_limit = 3
      @max_drafts_per_week = 10
      @llm_timeout = 120  # seconds
      @max_retries = 3
    end
  end
end
