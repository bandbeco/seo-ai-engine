module SeoAiEngine
  class LlmClient
    TIMEOUT = 120 # seconds
    MAX_RETRIES = 3
    CIRCUIT_BREAKER_THRESHOLD = 5 # consecutive failures
    CIRCUIT_BREAKER_TIMEOUT = 15.minutes # how long to keep circuit open

    # Custom error for circuit breaker
    class CircuitOpenError < StandardError; end

    class << self
      # Circuit breaker state (in production, use Redis for shared state)
      attr_accessor :failure_count, :circuit_opened_at

      def initialize_circuit_breaker
        @failure_count ||= 0
        @circuit_opened_at ||= nil
      end
      # Generate a content brief from an opportunity
      def generate_brief(opportunity)
        check_circuit_breaker!

        # Use mock mode if no API key is configured
        if use_mock_mode?
          response = mock_brief_response(opportunity)
          # Track estimated cost for brief generation
          BudgetTracker.record_cost(service: :llm, cost_gbp: 0.50)
          record_success
          return response
        end

        # Real implementation would use Anthropic gem here
        # client = Anthropic::Client.new(access_token: api_key)
        # response = client.messages(...)
        raise NotImplementedError, "Real API integration requires ANTHROPIC_API_KEY"
      rescue StandardError => e
        record_failure
        raise
      end

      # Generate content from a brief
      def generate_content(brief)
        check_circuit_breaker!

        # Use mock mode if no API key is configured
        if use_mock_mode?
          response = mock_content_response(brief)
          # Track estimated cost for content generation
          BudgetTracker.record_cost(service: :llm, cost_gbp: 2.50)
          record_success
          return response
        end

        # Real implementation would use Anthropic gem here
        raise NotImplementedError, "Real API integration requires ANTHROPIC_API_KEY"
      rescue StandardError => e
        record_failure
        raise
      end

      # Review content quality
      def review_content(draft)
        check_circuit_breaker!

        # Use mock mode if no API key is configured
        if use_mock_mode?
          response = mock_review_response(draft)
          # Track estimated cost for review
          BudgetTracker.record_cost(service: :llm, cost_gbp: 0.30)
          record_success
          return response
        end

        # Real implementation would use Anthropic gem here
        raise NotImplementedError, "Real API integration requires ANTHROPIC_API_KEY"
      rescue StandardError => e
        record_failure
        raise
      end

      private

      # Check if circuit breaker is open and raise error if so
      # Circuit breaker prevents cascading failures by stopping requests
      # after CIRCUIT_BREAKER_THRESHOLD consecutive failures
      def check_circuit_breaker!
        return unless circuit_open?

        # Circuit is open - don't allow requests
        time_remaining = time_until_circuit_closes
        raise CircuitOpenError,
              "Circuit breaker is open due to #{@failure_count} consecutive failures. " \
              "Will retry in #{time_remaining.round} seconds. " \
              "Check API credentials and service status."
      end

      # Check if circuit is currently open
      def circuit_open?
        return false unless @circuit_opened_at

        # Check if timeout has expired (half-open state)
        if Time.current > @circuit_opened_at + CIRCUIT_BREAKER_TIMEOUT
          # Timeout expired - move to half-open (allow one test request)
          Rails.logger.info "LlmClient: Circuit breaker timeout expired, entering half-open state"
          @circuit_opened_at = nil
          return false
        end

        true # Circuit still open
      end

      # Time in seconds until circuit closes
      def time_until_circuit_closes
        return 0 unless @circuit_opened_at

        (@circuit_opened_at + CIRCUIT_BREAKER_TIMEOUT - Time.current).to_i
      end

      # Record successful API call (resets failure count)
      def record_success
        initialize_circuit_breaker
        if @failure_count > 0
          Rails.logger.info "LlmClient: API call successful, resetting failure count from #{@failure_count}"
        end
        @failure_count = 0
        @circuit_opened_at = nil
      end

      # Record failed API call (increments failure count, opens circuit if threshold reached)
      def record_failure
        initialize_circuit_breaker
        @failure_count += 1
        Rails.logger.warn "LlmClient: API call failed (#{@failure_count}/#{CIRCUIT_BREAKER_THRESHOLD})"

        if @failure_count >= CIRCUIT_BREAKER_THRESHOLD
          @circuit_opened_at = Time.current
          Rails.logger.error "LlmClient: Circuit breaker OPENED after #{@failure_count} failures. " \
                             "Will remain open for #{CIRCUIT_BREAKER_TIMEOUT / 60} minutes."
        end
      end

      def use_mock_mode?
        # For User Story 2, always use mock mode
        # TODO: Implement real API integration in future user story
        true
      end

      def api_key
        # This would read from Rails.application.credentials or ENV
        # For now, always return nil to force mock mode
        Rails.application.credentials.dig(:anthropic, :api_key) || ENV["ANTHROPIC_API_KEY"]
      end

      def mock_brief_response(opportunity)
        {
          target_keyword: opportunity.keyword,
          suggested_title: "The Complete Guide to #{opportunity.keyword.titleize}",
          h2_suggestions: [
            "What is #{opportunity.keyword.titleize}?",
            "Benefits of #{opportunity.keyword.titleize}",
            "How to Choose the Right #{opportunity.keyword.titleize}",
            "Common Mistakes to Avoid",
            "Expert Tips and Best Practices"
          ],
          word_count_target: 1500,
          content_angle: "Comprehensive educational guide targeting business customers",
          key_points: [
            "Define #{opportunity.keyword} and its importance",
            "Explain environmental benefits",
            "Provide practical selection criteria",
            "Address common customer concerns",
            "Include product recommendations"
          ],
          internal_linking_opportunities: [ "related products", "category pages" ],
          meta_description_suggestion: "Discover everything you need to know about #{opportunity.keyword}. Expert guide covering benefits, selection tips, and best practices for businesses."
        }
      end

      def mock_content_response(brief)
        keyword = brief.target_keyword
        title = brief.suggested_structure["title"] || "The Complete Guide to #{keyword.titleize}"
        {
          title: title,
          body: mock_article_body(keyword),
          meta_title: "#{keyword.titleize} Guide | Sustainable Catering Supplies | Afida",
          meta_description: brief.suggested_structure["meta_description"] || "Discover everything you need to know about #{keyword}. Expert guide covering benefits, selection tips, and best practices for businesses.",
          target_keywords: [ keyword, "eco-friendly #{keyword}", "sustainable #{keyword}" ],
          generation_cost: 0.15 # Mock cost in GBP
        }
      end

      def mock_review_response(draft)
        {
          quality_score: 75,
          review_notes: {
            strengths: [
              "Well-structured with clear headings",
              "Good keyword integration",
              "Comprehensive coverage of topic"
            ],
            improvements: [
              "Could add more specific product examples",
              "Consider adding statistics or data points",
              "Internal linking could be stronger"
            ],
            seo_score: 78,
            readability_score: 72,
            keyword_density: "2.3%"
          },
          reviewer_model: "claude-3-5-sonnet-20241022"
        }
      end

      def mock_article_body(keyword)
        <<~MARKDOWN
          # The Complete Guide to #{keyword.titleize}

          In today's environmentally conscious business landscape, choosing the right #{keyword} has never been more important. This comprehensive guide will walk you through everything you need to know about selecting, using, and benefiting from #{keyword}.

          ## What is #{keyword.titleize}?

          #{keyword.titleize} refers to sustainable, environmentally friendly alternatives to traditional catering supplies. These products are designed to minimize environmental impact while maintaining the quality and functionality that businesses require.

          As more companies commit to reducing their carbon footprint, #{keyword} has become an essential part of sustainable operations. Whether you're running a café, restaurant, or catering business, understanding your options is crucial.

          ## Benefits of #{keyword.titleize}

          Making the switch to #{keyword} offers numerous advantages for your business:

          ### Environmental Impact

          By choosing #{keyword}, you're directly contributing to reducing waste in landfills. Many options are biodegradable, compostable, or made from recycled materials, significantly reducing your environmental footprint.

          ### Brand Reputation

          Customers increasingly prefer businesses that demonstrate environmental responsibility. Using #{keyword} shows your commitment to sustainability, helping you attract and retain environmentally conscious customers.

          ### Cost Effectiveness

          While some sustainable options may have a slightly higher upfront cost, many businesses find that the long-term benefits outweigh the initial investment. Improved brand reputation and customer loyalty often translate to increased revenue.

          ## How to Choose the Right #{keyword.titleize}

          Selecting the appropriate #{keyword} for your business requires careful consideration of several factors:

          ### Material Composition

          Different materials offer different benefits. Common options include:

          - **Paper-based products**: Recyclable and often compostable
          - **Plant-based plastics (PLA)**: Biodegradable alternatives to traditional plastic
          - **Bamboo and wood**: Renewable and sturdy options
          - **Recycled materials**: Giving new life to existing resources

          ### Certification Standards

          Look for products with recognized environmental certifications. These ensure that the products meet specific sustainability standards and have been independently verified.

          ### Practical Considerations

          Consider the practical needs of your business:
          - Heat resistance requirements
          - Liquid containment needs
          - Customer usage scenarios
          - Storage space availability

          ## Common Mistakes to Avoid

          When transitioning to #{keyword}, businesses often encounter a few common pitfalls:

          ### Not Planning for Proper Disposal

          Even compostable products need the right disposal conditions to break down properly. Ensure you have appropriate composting or recycling facilities in place.

          ### Choosing Price Over Quality

          The cheapest option isn't always the best value. Consider durability, functionality, and customer satisfaction alongside price.

          ### Ignoring Customer Education

          Help your customers understand the benefits of #{keyword}. Clear communication about your sustainability efforts can enhance their experience and appreciation.

          ## Expert Tips and Best Practices

          To maximize the benefits of #{keyword}, consider these expert recommendations:

          ### Start Small

          You don't need to switch everything at once. Begin with high-impact items and gradually expand your sustainable product range.

          ### Track Your Impact

          Monitor and measure the environmental impact of your switch to #{keyword}. This data can be valuable for marketing and continuous improvement.

          ### Partner with Reliable Suppliers

          Work with suppliers who share your commitment to sustainability and can provide consistent, quality products.

          ## Making the Switch to Sustainable Solutions

          Transitioning to #{keyword} is an investment in your business's future and the planet's wellbeing. By understanding the benefits, choosing the right products, and avoiding common mistakes, you can successfully implement sustainable practices that benefit your bottom line and the environment.

          Ready to make the switch? Explore our range of #{keyword} options designed specifically for businesses like yours. Our team can help you find the perfect sustainable solutions for your specific needs.

          ### Next Steps

          1. Assess your current product usage and identify priority items for replacement
          2. Review our product range and certifications
          3. Request samples to test quality and functionality
          4. Plan your transition timeline and budget
          5. Communicate your sustainability initiatives to customers

          For more information about specific products or to discuss your sustainability goals, contact our team today.
        MARKDOWN
      end
    end
  end
end
