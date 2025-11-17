module SeoAiEngine
  module Admin
    class OpportunitiesController < ApplicationController
      before_action :set_opportunity, only: [ :dismiss, :generate_content ]

      # GET /admin/opportunities
      def index
        @opportunities = Opportunity.all

        # Apply filters
        @opportunities = @opportunities.where(status: params[:status]) if params[:status].present?
        @opportunities = @opportunities.where("score >= ?", params[:min_score]) if params[:min_score].present?

        # Order by score descending (highest priority first)
        @opportunities = @opportunities.order(score: :desc)
      end

      # POST /admin/opportunities/:id/dismiss
      def dismiss
        @opportunity.update!(status: :dismissed)
        redirect_to admin_opportunities_path, notice: "Opportunity dismissed successfully."
      end

      # POST /admin/opportunities/:id/generate_content
      def generate_content
        # Enqueue job to generate content
        ContentGenerationJob.perform_later(@opportunity.id)

        redirect_to admin_opportunities_path,
          notice: "Content generation started for '#{@opportunity.query}'. Check drafts soon."
      rescue StandardError => e
        redirect_to admin_opportunities_path,
          alert: "Failed to start content generation: #{e.message}"
      end

      # POST /admin/opportunities/run_discovery
      def run_discovery
        # Trigger opportunity discovery job
        OpportunityDiscoveryJob.perform_later

        redirect_to admin_opportunities_path,
          notice: "Discovery job started. New opportunities will appear shortly (check Google Search Console and SerpAPI data)."
      rescue StandardError => e
        redirect_to admin_opportunities_path,
          alert: "Failed to start discovery: #{e.message}"
      end

      private

      def set_opportunity
        @opportunity = Opportunity.find(params[:id])
      end
    end
  end
end
