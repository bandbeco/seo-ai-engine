module SeoAiEngine
  class OpportunityDiscoveryJob < ApplicationJob
    queue_as :default

    # Minimum score threshold to save opportunity
    MIN_SCORE_THRESHOLD = 30

    # Sample keywords to discover opportunities from (mock data)
    SAMPLE_KEYWORDS = [
      "eco-friendly paper cups",
      "biodegradable food containers",
      "compostable coffee cups"
    ].freeze

    def perform
      Rails.logger.info "[OpportunityDiscoveryJob] Starting opportunity discovery"

      # Check budget enforcement (SerpAPI daily limit: 3 requests/day)
      unless BudgetTracker.within_serpapi_daily_limit?
        Rails.logger.warn "[OpportunityDiscoveryJob] SerpAPI daily limit reached. Queuing for next day."
        # Re-schedule for tomorrow
        OpportunityDiscoveryJob.set(wait: 1.day).perform_later
        return
      end

      # Step 1: Fetch keywords from Google Search Console
      keywords = fetch_keywords_from_gsc

      # Step 2: Analyze each keyword with SerpAPI and score (limit to 3/day)
      keywords.first(3).each do |keyword_data|
        analyze_and_save_opportunity(keyword_data)
      end

      Rails.logger.info "[OpportunityDiscoveryJob] Completed opportunity discovery"
    rescue GscClient::AuthenticationError => e
      Rails.logger.error "[OpportunityDiscoveryJob] GSC authentication failed: #{e.message}"
      # Don't raise - allow job to complete gracefully
    rescue StandardError => e
      Rails.logger.error "[OpportunityDiscoveryJob] Unexpected error: #{e.message}"
      raise
    end

    private

    def fetch_keywords_from_gsc
      # Try to fetch real data from Google Search Console
      begin
        gsc_client = GscClient.new
        if gsc_client.send(:authorize).present?
          # Real GSC data available
          Rails.logger.info "[OpportunityDiscoveryJob] Fetching real data from Google Search Console"
          return gsc_client.search_analytics(
            start_date: 28.days.ago.to_date,
            end_date: Date.today,
            dimensions: ["query"],
            min_impressions: 10,
            exclude_branded: true
          )
        end
      rescue GscClient::AuthenticationError, GscClient::APIError => e
        Rails.logger.warn "[OpportunityDiscoveryJob] GSC error, falling back to mock data: #{e.message}"
      end

      # Fallback to mock data if OAuth not configured or API fails
      Rails.logger.info "[OpportunityDiscoveryJob] Using mock data (configure OAuth for real data)"
      SAMPLE_KEYWORDS.map do |keyword|
        {
          keyword: keyword,
          impressions: rand(500..5000),
          clicks: rand(10..200),
          position: rand(10..50)
        }
      end
    end
    def analyze_and_save_opportunity(keyword_data)
      keyword = keyword_data[:keyword]

      # Step 2A: Get SERP analysis data
      serp_data = fetch_serp_data(keyword)
      return unless serp_data

      # Step 2B: Calculate opportunity score
      score_data = build_score_data(keyword_data, serp_data)
      score = calculate_score(score_data)

      # Step 2C: Only save if score meets threshold
      return if score < MIN_SCORE_THRESHOLD

      # Step 2D: Create or update opportunity
      save_opportunity(keyword, keyword_data, serp_data, score)

    rescue SerpClient::APIError => e
      Rails.logger.error "[OpportunityDiscoveryJob] SerpAPI error for '#{keyword}': #{e.message}"
      # Continue with next keyword
    end

    def fetch_serp_data(keyword)
      serp_client = SerpClient.new
      serp_client.analyze_keyword(keyword)
    rescue ArgumentError => e
      Rails.logger.error "[OpportunityDiscoveryJob] Invalid keyword '#{keyword}': #{e.message}"
      nil
    end

    def build_score_data(keyword_data, serp_data)
      {
        search_volume: serp_data[:search_volume] || 0,
        competition_difficulty: serp_data[:competition_difficulty],
        product_relevance: calculate_product_relevance(keyword_data[:keyword]),
        content_gap_score: calculate_content_gap(keyword_data)
      }
    end

    def calculate_score(score_data)
      scorer = OpportunityScorer.new(score_data)
      scorer.calculate
    end

    def calculate_product_relevance(keyword)
      # Simple heuristic: check if keyword contains product-related terms
      # TODO: Make this more sophisticated with actual product catalog matching
      product_terms = [ "cup", "container", "plate", "straw", "napkin", "packaging", "box" ]
      relevance = product_terms.any? { |term| keyword.downcase.include?(term) } ? 0.8 : 0.3
      relevance
    end

    def calculate_content_gap(keyword_data)
      # Content gap: how well are we ranking vs potential?
      # Higher gap = better opportunity
      # If we're not ranking (no position data), gap is high
      position = keyword_data[:position] || 50
      gap = [ 1.0 - (position / 50.0), 0.0 ].max
      gap
    end

    def save_opportunity(keyword, keyword_data, serp_data, score)
      # Find or initialize opportunity
      opportunity = Opportunity.find_or_initialize_by(keyword: keyword)

      # Determine opportunity type
      opportunity_type = if opportunity.new_record?
                          "new_content"
      elsif keyword_data[:position] && keyword_data[:position] <= 20
                          "quick_win"
      else
                          "optimize_existing"
      end

      # Set attributes
      opportunity.assign_attributes(
        search_volume: serp_data[:search_volume],
        competition_difficulty: serp_data[:competition_difficulty],
        score: score,
        opportunity_type: opportunity_type,
        current_position: keyword_data[:position],
        metadata: {
          impressions: keyword_data[:impressions],
          clicks: keyword_data[:clicks],
          serp_features: serp_data[:related_questions]&.any? ? "paa" : nil
        }.compact,
        discovered_at: opportunity.discovered_at || Time.current,
        status: opportunity.status || "pending"
      )

      if opportunity.save
        Rails.logger.info "[OpportunityDiscoveryJob] Saved opportunity: '#{keyword}' (score: #{score})"
      else
        Rails.logger.error "[OpportunityDiscoveryJob] Failed to save opportunity '#{keyword}': #{opportunity.errors.full_messages.join(', ')}"
      end
    end
  end
end
