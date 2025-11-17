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

        # Real RubyLLM implementation
        prompt = build_brief_prompt(opportunity)
        response = call_llm(
          model: SeoAiEngine.configuration.strategist_model,
          prompt: prompt
        )

        parse_brief_response(response, opportunity)
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

        # Real RubyLLM implementation
        prompt = build_content_prompt(brief)
        response = call_llm(
          model: SeoAiEngine.configuration.writer_model,
          prompt: prompt
        )

        parse_content_response(response, brief)
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

        # Real RubyLLM implementation
        prompt = build_review_prompt(draft)
        response = call_llm(
          model: SeoAiEngine.configuration.reviewer_model,
          prompt: prompt
        )

        parse_review_response(response)
      rescue StandardError => e
        record_failure
        raise
      end

      private

      # Call LLM using RubyLLM
      def call_llm(model:, prompt:)
        chat = RubyLLM.chat(model: model)
        response = chat.ask(prompt)
        record_success
        response.content
      end

      # Check if circuit breaker is open and raise error if so
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
        # Use real API if Anthropic key is configured
        anthropic_key = Rails.application.credentials.dig(:seo_ai_engine, :anthropic_api_key)
        anthropic_key.blank?
      end

      # Prompt builders
      def build_brief_prompt(opportunity)
        <<~PROMPT
          Create a comprehensive content brief for the keyword "#{opportunity.query}".

          Context:
          - Search Volume: #{opportunity.search_volume || 'Unknown'}
          - Competition: #{opportunity.competition_difficulty || 'Unknown'}
          - Current Position: #{opportunity.current_position || 'Not ranking'}

          Generate a content brief with:
          1. Target keyword and variations
          2. Suggested title (SEO-optimized, under 60 characters)
          3. H2 section suggestions (5-7 sections)
          4. Target word count (1500-2000 words)
          5. Content angle (e.g., "Educational guide for business buyers")
          6. Key points to cover
          7. Internal linking opportunities
          8. Meta description suggestion (under 160 characters)

          Format the response as JSON.
        PROMPT
      end

      def build_content_prompt(brief)
        <<~PROMPT
          Write a comprehensive, SEO-optimized article based on this content brief:

          Target Keyword: #{brief.target_keyword}
          Title: #{brief.suggested_structure["title"]}
          Word Count: #{brief.word_count_target || 1500} words
          Sections: #{brief.suggested_structure["h2_suggestions"]&.join(", ")}

          Requirements:
          - Write in professional, engaging style for B2B audience
          - Focus on eco-friendly catering supplies and sustainable packaging
          - Include practical advice and actionable tips
          - Naturally incorporate target keyword and variations
          - Use markdown formatting with proper headings
          - Write content that converts readers into customers

          Format the response with the article content in markdown.
        PROMPT
      end

      def build_review_prompt(draft)
        <<~PROMPT
          Review this content draft and provide a quality score with detailed feedback:

          Title: #{draft.title}
          Word Count: #{draft.body&.split&.count || 0} words
          Target Keywords: #{draft.target_keywords&.join(", ")}

          Content:
          #{draft.body&.truncate(2000)}

          Evaluate on:
          1. SEO optimization (keyword usage, structure, meta tags)
          2. Content quality (accuracy, depth, usefulness)
          3. Readability (clarity, flow, B2B tone)
          4. Engagement (hooks, CTAs, value proposition)
          5. Technical accuracy (about eco-friendly products)

          Provide:
          - Overall quality score (0-100)
          - SEO score (0-100)
          - Readability score (0-100)
          - List of strengths (3-5 points)
          - List of improvements (3-5 points)
          - Keyword density percentage

          Format the response as JSON.
        PROMPT
      end

      # Response parsers
      def parse_brief_response(response, opportunity)
        # For now, return structured mock data
        # TODO: Parse actual LLM JSON response
        mock_brief_response(opportunity)
      end

      def parse_content_response(response, brief)
        # For now, return structured mock data
        # TODO: Parse actual LLM response
        mock_content_response(brief)
      end

      def parse_review_response(response)
        # For now, return structured mock data
        # TODO: Parse actual LLM JSON response
        mock_review_response(nil)
      end

      # Mock responses (kept for backward compatibility and testing)
      def mock_brief_response(opportunity)
        {
          target_keyword: opportunity.query,
          suggested_title: "The Complete Guide to #{opportunity.query.titleize}",
          h2_suggestions: [
            "What is #{opportunity.query.titleize}?",
            "Benefits of #{opportunity.query.titleize}",
            "How to Choose the Right #{opportunity.query.titleize}",
            "Common Mistakes to Avoid",
            "Expert Tips and Best Practices"
          ],
          word_count_target: 1500,
          content_angle: "Comprehensive educational guide targeting business customers",
          key_points: [
            "Define #{opportunity.query} and its importance",
            "Explain environmental benefits",
            "Provide practical selection criteria",
            "Address common customer concerns",
            "Include product recommendations"
          ],
          internal_linking_opportunities: [ "related products", "category pages" ],
          meta_description_suggestion: "Discover everything you need to know about #{opportunity.query}. Expert guide covering benefits, selection tips, and best practices for businesses."
        }
      end

      def mock_content_response(brief)
        query = brief.target_keyword
        title = brief.suggested_structure["title"] || "The Complete Guide to #{query.titleize}"
        {
          title: title,
          body: mock_article_body(query),
          meta_title: "#{query.titleize} Guide | Sustainable Catering Supplies | Afida",
          meta_description: brief.suggested_structure["meta_description"] || "Discover everything you need to know about #{query}. Expert guide covering benefits, selection tips, and best practices for businesses.",
          target_keywords: [ query, "eco-friendly #{query}", "sustainable #{query}" ],
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
          reviewer_model: SeoAiEngine.configuration.reviewer_model
        }
      end

      def mock_article_body(query)
        <<~MARKDOWN
          # The Complete Guide to #{query.titleize}

          In today's environmentally conscious business landscape, choosing the right #{query} has never been more important. This comprehensive guide will walk you through everything you need to know about selecting, using, and benefiting from #{query}.

          ## What is #{query.titleize}?

          #{query.titleize} refers to sustainable, environmentally friendly alternatives to traditional catering supplies. These products are designed to minimize environmental impact while maintaining the quality and functionality that businesses require.

          As more companies commit to reducing their carbon footprint, #{query} has become an essential part of sustainable operations. Whether you're running a café, restaurant, or catering business, understanding your options is crucial.

          ## Benefits of #{query.titleize}

          Making the switch to #{query} offers numerous advantages for your business:

          ### Environmental Impact

          By choosing #{query}, you're directly contributing to reducing waste in landfills. Many options are biodegradable, compostable, or made from recycled materials, significantly reducing your environmental footprint.

          ### Brand Reputation

          Customers increasingly prefer businesses that demonstrate environmental responsibility. Using #{query} shows your commitment to sustainability, helping you attract and retain environmentally conscious customers.

          ### Cost Effectiveness

          While some sustainable options may have a slightly higher upfront cost, many businesses find that the long-term benefits outweigh the initial investment. Improved brand reputation and customer loyalty often translate to increased revenue.

          ## How to Choose the Right #{query.titleize}

          Selecting the appropriate #{query} for your business requires careful consideration of several factors:

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

          When transitioning to #{query}, businesses often encounter a few common pitfalls:

          ### Not Planning for Proper Disposal

          Even compostable products need the right disposal conditions to break down properly. Ensure you have appropriate composting or recycling facilities in place.

          ### Choosing Price Over Quality

          The cheapest option isn't always the best value. Consider durability, functionality, and customer satisfaction alongside price.

          ### Ignoring Customer Education

          Help your customers understand the benefits of #{query}. Clear communication about your sustainability efforts can enhance their experience and appreciation.

          ## Expert Tips and Best Practices

          To maximize the benefits of #{query}, consider these expert recommendations:

          ### Start Small

          You don't need to switch everything at once. Begin with high-impact items and gradually expand your sustainable product range.

          ### Track Your Impact

          Monitor and measure the environmental impact of your switch to #{query}. This data can be valuable for marketing and continuous improvement.

          ### Partner with Reliable Suppliers

          Work with suppliers who share your commitment to sustainability and can provide consistent, quality products.

          ## Making the Switch to Sustainable Solutions

          Transitioning to #{query} is an investment in your business's future and the planet's wellbeing. By understanding the benefits, choosing the right products, and avoiding common mistakes, you can successfully implement sustainable practices that benefit your bottom line and the environment.

          Ready to make the switch? Explore our range of #{query} options designed specifically for businesses like yours. Our team can help you find the perfect sustainable solutions for your specific needs.

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
