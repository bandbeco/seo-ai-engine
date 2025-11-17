# SEO AI Engine Configuration
# Loads API credentials from Rails encrypted credentials

SeoAiEngine.configure do |config|
  # LLM Configuration
  config.llm_provider = :anthropic
  config.strategist_model = "claude-sonnet-4"
  config.writer_model = "claude-sonnet-4"
  config.reviewer_model = "claude-haiku-4"

  # API Keys (from Rails credentials)
  config.anthropic_api_key = Rails.application.credentials.dig(:seo_ai_engine, :anthropic_api_key)

  # Google Search Console (Service Account)
  config.google_service_account = Rails.application.credentials.dig(:seo_ai_engine, :google_service_account)

  config.serpapi_key = Rails.application.credentials.dig(:seo_ai_engine, :serpapi_key)

  # Rate Limits
  config.serpapi_daily_limit = 999999  # Effectively no limit (set to a very high number)
  config.max_drafts_per_week = 999999  # No limit on content generation either

  # Timeouts
  config.claude_timeout = 120  # seconds
  config.max_retries = 3
end
