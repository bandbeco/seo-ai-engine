module SeoAiEngine
  class ContentDraft < ApplicationRecord
    self.table_name = "seo_ai_content_drafts"

    # Enums
    enum :status, {
      pending_review: "pending_review",
      approved: "approved",
      rejected: "rejected",
      published: "published"
    }, validate: true

    # Associations
    belongs_to :content_brief, class_name: "SeoAiEngine::ContentBrief", foreign_key: "seo_ai_content_brief_id"
    has_one :content_item, class_name: "SeoAiEngine::ContentItem", foreign_key: "seo_ai_content_draft_id", dependent: :destroy

    # Validations
    validates :content_type, presence: true
    validates :title, presence: true
    validates :body, presence: true
    validates :status, presence: true
    validates :content_brief, presence: true, uniqueness: true
    validate :quality_score_minimum
    validate :product_links_exist

    # Scopes
    scope :pending, -> { where(status: "pending_review") }
    scope :approved_drafts, -> { where(status: "approved") }
    scope :rejected, -> { where(status: "rejected") }
    scope :recent, -> { order(created_at: :desc) }

    private

    def quality_score_minimum
      if quality_score.present? && quality_score < 50
        errors.add(:quality_score, "must be at least 50 to save")
      end
    end

    # Validate that all product IDs in related_product_ids exist in the database
    # This ensures content doesn't reference deleted or non-existent products
    def product_links_exist
      return if related_product_ids.blank?

      # Query for products that exist
      existing_count = ::Product.where(id: related_product_ids).count

      # If any products are missing, add validation error
      if existing_count != related_product_ids.length
        missing_count = related_product_ids.length - existing_count
        errors.add(:related_product_ids, "contains #{missing_count} invalid product reference(s)")
      end
    end
  end
end
