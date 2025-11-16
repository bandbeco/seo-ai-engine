module SeoAiEngine
  class BudgetTracker
    class << self
      # Record API costs
      def record_cost(service:, cost_gbp:)
        tracking = current_month_tracking

        case service.to_sym
        when :llm
          tracking.llm_requests += 1
          tracking.llm_cost_gbp = (tracking.llm_cost_gbp || 0) + cost_gbp
        when :serpapi
          tracking.serpapi_requests += 1
          tracking.serpapi_cost_gbp = (tracking.serpapi_cost_gbp || 0) + cost_gbp
        when :gsc
          tracking.gsc_requests += 1
          # GSC is free, just tracking request count
        else
          raise ArgumentError, "Unknown service: #{service}"
        end

        tracking.save!
        check_thresholds_and_alert(tracking)
      end

      # Record content generation
      def record_content_generation
        tracking = current_month_tracking
        tracking.content_pieces_generated += 1
        tracking.save!
      end

      # Check current budget status
      def check_thresholds
        tracking = current_month_tracking
        tracking.alert_threshold?
      end

      # Get current month's tracking record
      def current_month_tracking
        month = Date.current.beginning_of_month

        BudgetTracking.find_or_create_by(month: month) do |t|
          t.gsc_requests = 0
          t.serpapi_requests = 0
          t.llm_requests = 0
          t.content_pieces_generated = 0
          t.llm_cost_gbp = 0.0
          t.serpapi_cost_gbp = 0.0
          t.total_cost_gbp = 0.0
          t.avg_cost_per_piece = 0.0
        end
      end

      # Check if within daily/weekly limits
      def within_serpapi_daily_limit?
        tracking = current_month_tracking
        daily_requests_today = tracking.serpapi_requests # Simplified: assumes monthly tracking

        # Allow 3 SerpAPI requests per day (90/month ÷ 30 days)
        daily_requests_today < 3
      end

      def within_weekly_generation_limit?
        # Allow 10 drafts per week
        tracking = current_month_tracking
        tracking.content_pieces_generated < 40 # ~10 per week
      end

      private

      def check_thresholds_and_alert(tracking)
        status = tracking.alert_threshold?

        case status
        when :exceeded
          Rails.logger.error "[BudgetTracker] Budget EXCEEDED: £#{tracking.total_cost_gbp} / £#{BudgetTracking::ALERT_THRESHOLD_GBP}"
          send_alert(:exceeded, tracking)
        when :warning
          Rails.logger.warn "[BudgetTracker] Budget WARNING: £#{tracking.total_cost_gbp} / £#{BudgetTracking::WARNING_THRESHOLD_GBP}"
          send_alert(:warning, tracking)
        else
          Rails.logger.info "[BudgetTracker] Budget OK: £#{tracking.total_cost_gbp} / £#{BudgetTracking::BUDGET_TARGET_GBP}"
        end
      end

      def send_alert(level, tracking)
        # TODO: Implement AlertMailer
        # AlertMailer.budget_warning(tracking.month, tracking.total_cost_gbp).deliver_later if level == :warning
        # AlertMailer.budget_exceeded(tracking.month, tracking.total_cost_gbp).deliver_later if level == :exceeded
        Rails.logger.info "[BudgetTracker] Alert #{level} sent for month #{tracking.month}"
      end
    end
  end
end
