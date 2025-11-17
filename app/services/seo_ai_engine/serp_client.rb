require "google_search_results"

module SeoAiEngine
  class SerpClient
    class APIError < StandardError; end

    # Analyzes a keyword using SerpAPI to gather SERP data
    def analyze_keyword(keyword)
      raise ArgumentError, "Keyword cannot be nil or empty" if keyword.nil? || keyword.strip.empty?

      # Check if SerpAPI key is configured
      unless SeoAiEngine.configuration.serpapi_key.present?
        Rails.logger.warn "[SerpClient] No SerpAPI key configured, using mock data"
        return generate_mock_data(keyword)
      end

      # Use real SerpAPI
      begin
        search = GoogleSearch.new(
          q: keyword,
          api_key: SeoAiEngine.configuration.serpapi_key,
          location: "United Kingdom",
          gl: "uk",
          hl: "en"
        )

        results = search.get_hash

        # Transform to our format
        serp_data = {
          keyword: keyword,
          search_volume: estimate_search_volume_from_serp(results),
          competition_difficulty: analyze_competition(results),
          organic_results: extract_organic_results(results),
          related_questions: extract_related_questions(results)
        }

        # Track SerpAPI cost
        BudgetTracker.record_cost(service: :serpapi, cost_gbp: 1.33)

        Rails.logger.info "[SerpClient] Analyzed '#{keyword}': #{serp_data[:organic_results]&.count || 0} results"
        serp_data
      rescue => e
        Rails.logger.error "[SerpClient] API error for '#{keyword}': #{e.message}"
        # Fall back to mock data on error
        generate_mock_data(keyword)
      end
    end

    private

    def estimate_search_volume_from_serp(results)
      # SerpAPI doesn't directly provide search volume
      # Estimate based on SERP features and result count
      has_ads = results[:ads]&.any?
      has_shopping = results[:shopping_results]&.any?
      has_paa = results[:related_questions]&.any?

      # Rough heuristic: more SERP features = higher volume
      if has_ads && has_shopping
        rand(5000..10000)  # High volume
      elsif has_ads || has_paa
        rand(1000..5000)   # Medium volume
      else
        rand(100..1000)    # Lower volume
      end
    end

    def analyze_competition(results)
      # Analyze competition based on domain authority of ranking sites
      organic = results[:organic_results] || []
      return "low" if organic.empty?

      # Check for high-authority domains
      high_authority_domains = ["amazon", "ebay", "walmart", "gov.uk", "wikipedia"]
      authority_count = organic.first(10).count do |result|
        link = result[:link] || ""
        high_authority_domains.any? { |domain| link.include?(domain) }
      end

      if authority_count >= 5
        "high"
      elsif authority_count >= 2
        "medium"
      else
        "low"
      end
    end

    def extract_organic_results(results)
      organic = results[:organic_results] || []
      organic.first(3).map do |result|
        {
          position: result[:position],
          title: result[:title],
          link: result[:link],
          snippet: result[:snippet]
        }
      end
    end

    def extract_related_questions(results)
      paa = results[:related_questions] || []
      paa.first(3).map { |q| q[:question] }.compact
    end

    def generate_mock_data(keyword)
      {
        keyword: keyword,
        search_volume: calculate_mock_search_volume(keyword),
        competition_difficulty: determine_mock_competition(keyword),
        organic_results: generate_mock_organic_results(keyword),
        related_questions: generate_mock_related_questions(keyword)
      }
    end

    def calculate_mock_search_volume(keyword)
      # Estimate volume based on keyword characteristics
      word_count = keyword.split.length
      has_brand = keyword.downcase.match?(/wholesale|bulk|supplier|distributor/)
      has_product = keyword.downcase.match?(/cup|straw|napkin|box|container|plate/)

      base_volume = case word_count
      when 1..2 then 7000
      when 3..4 then 3000
      else 1000
      end

      # Adjust for keyword type
      base_volume *= 1.5 if has_product
      base_volume *= 0.7 if has_brand

      base_volume.to_i
    end

    def determine_mock_competition(keyword)
      # Heuristic based on keyword characteristics
      has_qualifier = keyword.downcase.match?(/best|top|review|guide|how to/)
      has_commercial = keyword.downcase.match?(/buy|price|cheap|wholesale|bulk/)

      if has_commercial && has_qualifier
        "high"
      elsif has_commercial || has_qualifier
        "medium"
      else
        "low"
      end
    end

    def generate_mock_organic_results(keyword)
      (1..3).map do |position|
        {
          position: position,
          title: "#{keyword.titleize} - #{[ 'Ultimate Guide', 'Best in 2024', 'Buy Online' ][position - 1]}",
          link: "https://example#{position}.com/#{keyword.parameterize}",
          snippet: "#{[ 'Everything you need to know', 'Top rated products and reviews', 'Shop our selection at great prices' ][position - 1]} about #{keyword}"
        }
      end
    end

    def generate_mock_related_questions(keyword)
      [
        "What are the best #{keyword}?",
        "How to choose #{keyword}?",
        "Where to buy #{keyword}?"
      ]
    end
  end
end
