module SeoAiEngine
  class ContentWriter
    attr_reader :brief, :draft

    def initialize(brief)
      @brief = brief
    end

    # Generate a content draft from the brief
    def generate_draft
      # Call LLM to generate content
      llm_response = LlmClient.generate_content(brief)

      # Create ContentDraft record
      @draft = ContentDraft.create!(
        content_brief: brief,
        content_type: "blog_post",
        title: llm_response[:title],
        body: llm_response[:body],
        meta_title: llm_response[:meta_title],
        meta_description: llm_response[:meta_description],
        target_keywords: llm_response[:target_keywords],
        status: "pending_review",
        generation_cost_gbp: llm_response[:generation_cost]
      )

      Rails.logger.info "ContentWriter: Created draft ##{@draft.id} for brief ##{brief.id}"

      @draft
    rescue StandardError => e
      Rails.logger.error "ContentWriter failed: #{e.message}"
      raise
    end
  end
end
