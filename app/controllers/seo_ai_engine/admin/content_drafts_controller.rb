module SeoAiEngine
  module Admin
    class ContentDraftsController < ApplicationController
      before_action :set_draft, only: [ :show, :approve, :reject ]

      # GET /admin/content_drafts
      def index
        @drafts = ContentDraft.includes(:content_brief)
          .order(created_at: :desc)

        # Filter by status if provided
        if params[:status].present?
          @drafts = @drafts.where(status: params[:status])
        else
          # Default to pending review
          @drafts = @drafts.where(status: "pending_review")
        end
      end

      # GET /admin/content_drafts/:id
      def show
        @brief = @draft.content_brief
        @opportunity = @brief.opportunity
      end

      # POST /admin/content_drafts/:id/approve
      def approve
        # Create ContentItem from the draft
        content_item = ContentItem.create!(
          content_draft: @draft,
          title: @draft.title,
          body: @draft.body,
          meta_title: @draft.meta_title,
          meta_description: @draft.meta_description,
          target_keywords: @draft.target_keywords,
          published_at: Time.current
        )

        # Update draft status
        @draft.update!(status: "published")

        redirect_to admin_content_item_path(content_item),
          notice: "Content approved and published successfully!"
      rescue StandardError => e
        redirect_to admin_content_draft_path(@draft),
          alert: "Failed to approve content: #{e.message}"
      end

      # POST /admin/content_drafts/:id/reject
      def reject
        # Mark draft as rejected
        @draft.update!(status: "rejected")

        # Return opportunity to pending so it can be retried
        opportunity = @draft.content_brief.opportunity
        opportunity.update!(status: "pending")

        redirect_to admin_content_drafts_path,
          notice: "Draft rejected. Opportunity returned to pending."
      rescue StandardError => e
        redirect_to admin_content_draft_path(@draft),
          alert: "Failed to reject content: #{e.message}"
      end

      private

      def set_draft
        @draft = ContentDraft.find(params[:id])
      end
    end
  end
end
