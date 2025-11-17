module SeoAiEngine
  class OpportunityDiscoveryJob < ApplicationJob
    queue_as :default

    # Minimum score threshold to save opportunity
    MIN_SCORE_THRESHOLD = 30

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
      search_queries_data = fetch_queries_from_gsc

      # Step 2: Analyze each query with SerpAPI and score
      search_queries_data.each do |search_query_data|
        analyze_and_save_opportunity(search_query_data)
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

    def fetch_queries_from_gsc
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
        Rails.logger.warn "[OpportunityDiscoveryJob] GSC error: #{e.message}"
      end

      # Return empty array if no data available
      Rails.logger.warn "[OpportunityDiscoveryJob] No GSC data available"
      []
    end

    def analyze_and_save_opportunity(search_query_data)
      query = search_query_data[:query]

      # Step 2A: Get SERP analysis data
      serp_data = fetch_serp_data(query)
      return unless serp_data.present?

      # Step 2B: Calculate opportunity score
      score_data = build_score_data(search_query_data, serp_data)
      score = calculate_score(score_data)

      # Step 2C: Only save if score meets threshold
      return if score < MIN_SCORE_THRESHOLD

      # Step 2D: Create or update opportunity
      save_opportunity(query, search_query_data, serp_data, score)

    rescue SerpClient::APIError => e
      Rails.logger.error "[OpportunityDiscoveryJob] SerpAPI error for '#{keyword}': #{e.message}"
      # Continue with next keyword
    end

    def fetch_serp_data(query)
      serp_client = SerpClient.new
      serp_client.analyze_keyword(query)
    rescue ArgumentError => e
      Rails.logger.error "[OpportunityDiscoveryJob] Invalid query '#{query}': #{e.message}"
      nil
    end

    def build_score_data(search_query_data, serp_data)
      query = search_query_data[:query]
      search_volume = search_query_data[:impressions] || 0
      competition_difficulty = serp_data[:competition_difficulty]
      product_relevance = calculate_product_relevance(query)
      content_gap_score = calculate_content_gap(search_query_data[:position])

      {
        search_volume: search_volume,
        competition_difficulty: competition_difficulty,
        product_relevance: product_relevance,
        content_gap_score: content_gap_score
      }
    end

    def calculate_score(score_data)
      scorer = OpportunityScorer.new(score_data)
      scorer.calculate
    end

    def calculate_product_relevance(query)
      # Simple heuristic: check if keyword contains product-related terms
      product_terms = [
        # Core product types from catalog
        "cup", "cups",
        "lid", "lids",
        "container", "containers",
        "bowl", "bowls",
        "box", "boxes",
        "bag", "bags",
        "straw", "straws",
        "napkin", "napkins",
        "cutlery",
        "fork", "forks",
        "knife", "knives",
        "spoon", "spoons",
        "stirrer", "stirrers",
        "tray", "trays",
        "carrier",
        # Specific product categories
        "pizza box",
        "ice cream cup",
        "soup container",
        "food bowl",
        "coffee cup",
        "hot cup",
        "cold cup",
        "takeaway bag",
        "carrier tray",
        "cup carrier",
        "deli box",
        # Product attributes & materials
        "compostable",
        "recyclable",
        "biodegradable",
        "disposable",
        "eco-friendly",
        "sustainable",
        "paper",
        "kraft",
        "bamboo",
        "wooden",
        "bagasse",
        "rpet",
        "pulp",
        "airlaid",
        # Cup/container types
        "double wall",
        "single wall",
        "ripple wall",
        "dome lid",
        "flat lid",
        "sip lid",
        # Use cases
        "takeaway",
        "packaging",
        "food service",
        "catering",
        "coffee shop",
        "restaurant"
      ]

      relevance = product_terms.any? { |term| query.downcase.include?(term) } ? 0.8 : 0.3
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

    def save_opportunity(query, search_query_data, serp_data, score)
      # Find or initialize opportunity
      opportunity = Opportunity.find_or_initialize_by(query: query)

      # Determine opportunity type
      opportunity_type = if opportunity.new_record?
                          "new_content"
      elsif search_query_data[:position].to_i <= 20
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
        current_position: search_query_data[:position],
        metadata: {
          impressions: search_query_data[:impressions],
          clicks: search_query_data[:clicks],
          serp_features: serp_data[:related_questions]&.any? ? "paa" : nil
        }.compact,
        discovered_at: opportunity.discovered_at || Time.current,
        status: opportunity.status || "pending"
      )

      if opportunity.save
        Rails.logger.info "[OpportunityDiscoveryJob] Saved opportunity: '#{query}' (score: #{score})"
      else
        Rails.logger.error "[OpportunityDiscoveryJob] Failed to save opportunity '#{query}': #{opportunity.errors.full_messages.join(', ')}"
      end
    end
  end
end
