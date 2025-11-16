module SeoAiEngine
  module Admin
    class ContentItemsController < ApplicationController
      before_action :set_content_item, only: [ :show ]

      # GET /admin/content_items
      def index
        @content_items = ContentItem.includes(:content_draft)
          .order(published_at: :desc)
      end

      # GET /admin/content_items/:id
      def show
        @draft = @content_item.content_draft
        @brief = @draft.content_brief
        @opportunity = @brief.opportunity
      end

      private

      def set_content_item
        @content_item = ContentItem.find(params[:id])
      end
    end
  end
end
