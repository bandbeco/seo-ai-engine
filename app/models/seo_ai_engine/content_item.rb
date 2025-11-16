module SeoAiEngine
  class ContentItem < ApplicationRecord
    self.table_name = "seo_ai_content_items"

    # Associations
    belongs_to :content_draft, class_name: "SeoAiEngine::ContentDraft", foreign_key: "seo_ai_content_draft_id"
    has_many :performance_snapshots, class_name: "SeoAiEngine::PerformanceSnapshot", foreign_key: "seo_ai_content_item_id", dependent: :destroy

    # Validations
    validates :slug, presence: true, uniqueness: true
    validates :title, presence: true
    validates :body, presence: true
    validates :published_at, presence: true
    validates :content_draft, presence: true

    # Callbacks
    before_validation :generate_slug, on: :create

    # Scopes
    scope :published, -> { order(published_at: :desc) }
    scope :recent, -> { order(published_at: :desc) }

    # Use slug for URLs
    def to_param
      slug
    end

    private

    def generate_slug
      return if slug.present?

      base_slug = title.parameterize
      candidate_slug = base_slug
      counter = 1

      while ContentItem.exists?(slug: candidate_slug)
        candidate_slug = "#{base_slug}-#{counter}"
        counter += 1
      end

      self.slug = candidate_slug
    end
  end
end
