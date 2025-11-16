module SeoAiEngine
  class OpportunityScorer
    # Scoring weights (must sum to 100%)
    SEARCH_VOLUME_WEIGHT = 0.40  # 40%
    COMPETITION_WEIGHT = 0.30     # 30%
    RELEVANCE_WEIGHT = 0.20       # 20%
    CONTENT_GAP_WEIGHT = 0.10     # 10%

    # Competition difficulty points
    COMPETITION_POINTS = {
      "low" => 30,
      "medium" => 15,
      "high" => 5
    }.freeze

    # Search volume normalization (logarithmic scale)
    # Assumes 10,000 searches/month = max score
    MAX_SEARCH_VOLUME = 10_000

    def initialize(opportunity_data)
      @search_volume = opportunity_data[:search_volume] || 0
      @competition_difficulty = opportunity_data[:competition_difficulty]
      @product_relevance = opportunity_data[:product_relevance] || 0.0
      @content_gap_score = opportunity_data[:content_gap_score] || 0.0
    end

    def calculate
      total_score = 0.0

      # 1. Search Volume (40 points max)
      total_score += calculate_volume_score

      # 2. Competition Difficulty (30 points max)
      total_score += calculate_competition_score

      # 3. Product Relevance (20 points max)
      total_score += calculate_relevance_score

      # 4. Content Gap (10 points max)
      total_score += calculate_content_gap_score

      # Return as integer, clamped 0-100
      total_score.round.clamp(0, 100)
    end

    private

    def calculate_volume_score
      return 0 if @search_volume.nil? || @search_volume <= 0

      # Logarithmic scale: normalize volume to 0-1 range
      normalized = Math.log10([ @search_volume, 1 ].max) / Math.log10(MAX_SEARCH_VOLUME)
      normalized = normalized.clamp(0.0, 1.0)

      # Apply weight (40% of total score)
      (normalized * SEARCH_VOLUME_WEIGHT * 100).round(2)
    end

    def calculate_competition_score
      return 0 if @competition_difficulty.nil?

      points = COMPETITION_POINTS[@competition_difficulty] || 0
      points.to_f
    end

    def calculate_relevance_score
      # Product relevance is already 0-1 scale
      (@product_relevance * RELEVANCE_WEIGHT * 100).round(2)
    end

    def calculate_content_gap_score
      # Content gap is already 0-1 scale
      (@content_gap_score * CONTENT_GAP_WEIGHT * 100).round(2)
    end
  end
end
