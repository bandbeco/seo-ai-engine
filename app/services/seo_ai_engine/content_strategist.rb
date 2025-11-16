module SeoAiEngine
  class ContentStrategist
    attr_reader :opportunity, :brief

    def initialize(opportunity)
      @opportunity = opportunity
    end

    # Create a content brief from the opportunity
    def create_brief
      # Call LLM to generate brief
      llm_response = LlmClient.generate_brief(opportunity)

      # Create ContentBrief record with suggested_structure as JSONB
      @brief = ContentBrief.create!(
        opportunity: opportunity,
        target_keyword: llm_response[:target_keyword],
        search_intent: llm_response[:content_angle] || "informational",
        suggested_structure: {
          title: llm_response[:suggested_title],
          headings: llm_response[:h2_suggestions] || [],
          word_count_target: llm_response[:word_count_target] || 1500,
          key_points: llm_response[:key_points] || [],
          meta_description: llm_response[:meta_description_suggestion]
        },
        internal_links: {
          opportunities: llm_response[:internal_linking_opportunities] || []
        },
        created_by_model: "claude-3-5-sonnet-20241022"
      )

      Rails.logger.info "ContentStrategist: Created brief ##{@brief.id} for opportunity ##{opportunity.id}"

      @brief
    rescue StandardError => e
      Rails.logger.error "ContentStrategist failed: #{e.message}"
      raise
    end
  end
end
