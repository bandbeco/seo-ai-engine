module SeoAiEngine
  module ApplicationHelper
    # Format trend percentage with + or -
    def format_trend(value)
      return "N/A" if value.nil?
      value >= 0 ? "+#{value}%" : "#{value}%"
    end

    # Color code for trend (green for positive, red for negative)
    def trend_color(value)
      return "text-base-content/50" if value.nil? || value.zero?
      value > 0 ? "text-success" : "text-error"
    end

    # Budget progress bar color based on status
    def budget_progress_color(status)
      case status
      when :exceeded
        "progress-error"
      when :warning
        "progress-warning"
      else
        "progress-success"
      end
    end
  end
end
