module SeoAiEngine
  class BudgetTracking < ApplicationRecord
    self.table_name = "seo_ai_budget_trackings"

    # Constants
    BUDGET_TARGET_GBP = 90.0
    WARNING_THRESHOLD_GBP = 80.0
    ALERT_THRESHOLD_GBP = 100.0

    # Validations
    validates :month, presence: true, uniqueness: true
    validates :gsc_requests, numericality: { greater_than_or_equal_to: 0, only_integer: true }
    validates :serpapi_requests, numericality: { greater_than_or_equal_to: 0, only_integer: true }
    validates :llm_requests, numericality: { greater_than_or_equal_to: 0, only_integer: true }
    validates :content_pieces_generated, numericality: { greater_than_or_equal_to: 0, only_integer: true }

    # Scopes
    scope :recent, -> { order(month: :desc) }
    scope :current_month, -> { where(month: Date.current.beginning_of_month) }
    scope :recent_months, ->(count = 6) { where("month >= ?", count.months.ago.beginning_of_month).order(month: :desc) }

    # Callbacks
    before_save :calculate_totals

    # Methods
    def within_budget?
      total_cost_gbp <= BUDGET_TARGET_GBP
    end

    def alert_threshold?
      return :exceeded if total_cost_gbp >= ALERT_THRESHOLD_GBP
      return :warning if total_cost_gbp >= WARNING_THRESHOLD_GBP
      :ok
    end

    def budget_percentage
      return 0.0 if BUDGET_TARGET_GBP.zero?
      ((total_cost_gbp / BUDGET_TARGET_GBP) * 100).round(2)
    end

    def savings_vs_agency(agency_cost = 600.0)
      agency_cost - total_cost_gbp
    end

    private

    def calculate_totals
      self.total_cost_gbp = (llm_cost_gbp || 0) + (serpapi_cost_gbp || 0)

      if content_pieces_generated.positive?
        self.avg_cost_per_piece = total_cost_gbp / content_pieces_generated
      else
        self.avg_cost_per_piece = 0.0
      end
    end
  end
end
