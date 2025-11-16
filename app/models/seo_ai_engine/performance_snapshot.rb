module SeoAiEngine
  class PerformanceSnapshot < ApplicationRecord
    self.table_name = "seo_ai_performance_snapshots"

    # Associations
    belongs_to :content_item, class_name: "SeoAiEngine::ContentItem", foreign_key: "seo_ai_content_item_id", optional: true

    # Validations
    validates :period_start, presence: true
    validates :period_end, presence: true
    validates :impressions, numericality: { greater_than_or_equal_to: 0, only_integer: true }
    validates :clicks, numericality: { greater_than_or_equal_to: 0, only_integer: true }
    validate :period_end_after_start

    # Scopes
    scope :recent, -> { order(period_end: :desc) }
    scope :recent_weeks, ->(weeks = 12) { where("period_end >= ?", weeks.weeks.ago).order(period_end: :desc) }
    scope :for_period, ->(start_date, end_date) { where(period_start: start_date, period_end: end_date) }
    scope :site_wide, -> { where(seo_ai_content_item_id: nil) }

    # Methods
    def calculate_ctr
      return 0.0 if impressions.zero?
      (clicks.to_f / impressions * 100).round(2)
    end

    def calculate_traffic_value(value_per_click = 2.50)
      (clicks * value_per_click).round(2)
    end

    def week_over_week_change(previous_snapshot)
      return nil unless previous_snapshot

      {
        impressions: calculate_percentage_change(previous_snapshot.impressions, impressions),
        clicks: calculate_percentage_change(previous_snapshot.clicks, clicks),
        ctr: calculate_percentage_change(previous_snapshot.calculate_ctr, calculate_ctr)
      }
    end

    private

    def period_end_after_start
      if period_start.present? && period_end.present? && period_end < period_start
        errors.add(:period_end, "must be after period start")
      end
    end

    def calculate_percentage_change(old_value, new_value)
      return 0.0 if old_value.zero?
      ((new_value - old_value).to_f / old_value * 100).round(2)
    end
  end
end
