module SeoAiEngine
  module Admin
    class PerformanceController < ApplicationController
      def index
        # Overview metrics
        @total_articles = ContentItem.published.count
        @total_impressions = recent_total_impressions
        @total_clicks = recent_total_clicks
        @traffic_value = calculate_traffic_value(@total_clicks)

        # Content performance table
        @content_performance = build_content_performance_table

        # Budget tracking
        @current_budget = BudgetTracker.current_month_tracking
        @budget_status = @current_budget.alert_threshold?

        # ROI calculation
        @monthly_cost = @current_budget.total_cost_gbp
        @agency_cost = 600.0
        @monthly_savings = @agency_cost - @monthly_cost

        # Recent budget history
        @budget_history = BudgetTracking.recent_months(6)
      end

      private

      def recent_total_impressions
        PerformanceSnapshot
          .recent_weeks(4)
          .sum(:impressions)
      end

      def recent_total_clicks
        PerformanceSnapshot
          .recent_weeks(4)
          .sum(:clicks)
      end

      def calculate_traffic_value(clicks, value_per_click = 2.50)
        (clicks * value_per_click).round(2)
      end

      def build_content_performance_table
        ContentItem.published.includes(:performance_snapshots).map do |item|
          latest_snapshot = item.performance_snapshots.order(period_end: :desc).first
          previous_snapshot = item.performance_snapshots
            .where("period_end < ?", latest_snapshot&.period_end || Date.current)
            .order(period_end: :desc)
            .first

          trends = latest_snapshot&.week_over_week_change(previous_snapshot)

          {
            item: item,
            impressions: latest_snapshot&.impressions || 0,
            clicks: latest_snapshot&.clicks || 0,
            ctr: latest_snapshot&.calculate_ctr || 0.0,
            traffic_value: latest_snapshot&.calculate_traffic_value || 0.0,
            trends: trends,
            weeks_live: weeks_since_publish(item.published_at)
          }
        end.sort_by { |data| -data[:clicks] } # Sort by clicks descending
      end

      def weeks_since_publish(published_at)
        return 0 unless published_at
        ((Date.current - published_at.to_date) / 7).to_i
      end
    end
  end
end
