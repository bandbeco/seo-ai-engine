module SeoAiEngine
  class ContentGenerationJob < ApplicationJob
    queue_as :default

    # Orchestrates the full content generation workflow:
    # Opportunity -> Brief -> Draft -> Review
    def perform(opportunity_id)
      opportunity = Opportunity.find(opportunity_id)

      Rails.logger.info "ContentGenerationJob: Starting for opportunity ##{opportunity.id}"

      # Check budget enforcement (weekly limit: 10 drafts/week)
      unless BudgetTracker.within_weekly_generation_limit?
        Rails.logger.warn "ContentGenerationJob: Weekly generation limit reached. Postponing."
        # Re-queue for next week
        ContentGenerationJob.set(wait: 1.week).perform_later(opportunity_id)
        return
      end

      # Update opportunity status
      opportunity.update!(status: "in_progress")

      # Step 1: Create content brief
      strategist = ContentStrategist.new(opportunity)
      brief = strategist.create_brief

      # Step 2: Generate content draft
      writer = ContentWriter.new(brief)
      draft = writer.generate_draft

      # Step 3: Review content quality
      reviewer = ContentReviewer.new(draft)
      reviewer.review

      # Track content generation
      BudgetTracker.record_content_generation

      # Update opportunity status
      opportunity.update!(status: "completed")

      Rails.logger.info "ContentGenerationJob: Completed for opportunity ##{opportunity.id}, draft ##{draft.id}"

      draft
    rescue StandardError => e
      Rails.logger.error "ContentGenerationJob failed for opportunity ##{opportunity_id}: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")

      # Update opportunity status to pending so it can be retried
      if opportunity
        opportunity.update!(status: "pending")
      end

      # Re-raise so job can be retried
      raise
    end
  end
end
