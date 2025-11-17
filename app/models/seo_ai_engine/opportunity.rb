module SeoAiEngine
  class Opportunity < ApplicationRecord
    self.table_name = "seo_ai_opportunities"

    # Enums
    enum :opportunity_type, {
      new_content: "new_content",
      optimize_existing: "optimize_existing",
      quick_win: "quick_win"
    }, validate: true

    enum :competition_difficulty, {
      low: "low",
      medium: "medium",
      high: "high"
    }, validate: { allow_nil: true }

    enum :status, {
      pending: "pending",
      in_progress: "in_progress",
      completed: "completed",
      dismissed: "dismissed"
    }, validate: true

    # Validations
    validates :query, presence: true, uniqueness: true
    validates :opportunity_type, presence: true
    validates :score, presence: true, numericality: {
      greater_than_or_equal_to: 0,
      less_than_or_equal_to: 100,
      only_integer: true
    }
    validates :discovered_at, presence: true
    validates :search_volume, numericality: { greater_than_or_equal_to: 0, only_integer: true }, allow_nil: true
    validates :current_position, numericality: { greater_than_or_equal_to: 0, only_integer: true }, allow_nil: true

    # Scopes
    scope :high_priority, -> { where(score: 70..100) }
    scope :medium_priority, -> { where(score: 50..69) }
    scope :low_priority, -> { where(score: 0..49) }
    scope :recent, -> { order(discovered_at: :desc) }

    # Associations
    has_one :content_brief, class_name: "SeoAiEngine::ContentBrief", foreign_key: :seo_ai_opportunity_id, dependent: :destroy
  end
end
