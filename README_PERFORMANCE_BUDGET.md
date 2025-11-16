# Performance Tracking & Budget Management

This document describes User Story 3 (Performance Tracking) and User Story 4 (Budget Management) implementation for the AI SEO Engine.

## User Story 3: Performance Tracking

**Goal**: Weekly GSC performance tracking, ROI dashboard showing traffic value vs £600 agency cost

### Components Implemented

#### 1. PerformanceSnapshot Model (`app/models/seo_ai_engine/performance_snapshot.rb`)

Enhanced model with methods for calculations:

- `calculate_ctr()` - Calculates click-through rate as a percentage
- `calculate_traffic_value(value_per_click = 2.50)` - Estimates traffic value in GBP
- `week_over_week_change(previous_snapshot)` - Calculates trend percentages

**Scopes**:
- `recent_weeks(weeks = 12)` - Get snapshots from last N weeks
- `site_wide` - Get site-wide snapshots (not tied to specific content)
- `for_period(start_date, end_date)` - Get snapshots for date range

#### 2. PerformanceTrackingJob (`app/jobs/seo_ai_engine/performance_tracking_job.rb`)

Background job that runs weekly (Sunday 3am recommended) to:

1. Track site-wide performance (impressions, clicks, avg position)
2. Track per-article performance for all published ContentItems
3. Calculate week-over-week trends
4. Flag underperformers (<50 impressions/week after 8 weeks)

**Mock Implementation**: Currently uses mock GSC data. Real implementation requires:
- Google Search Console API integration
- OAuth 2.0 authentication
- Query filtering by URL for per-article stats

#### 3. PerformanceController (`app/controllers/seo_ai_engine/admin/performance_controller.rb`)

Admin dashboard controller providing:

- Overview metrics (total articles, impressions, clicks, traffic value)
- Content performance table with trends
- Budget tracking integration
- ROI calculation (savings vs £600/month agency cost)

#### 4. Performance Dashboard View (`app/views/seo_ai_engine/admin/performance/index.html.erb`)

DaisyUI-based dashboard featuring:

- **Overview cards**: Total articles, impressions, clicks, traffic value
- **Budget section**: Monthly costs, progress bar, alert status
- **Budget breakdown**: LLM costs, SerpAPI costs, avg cost per article
- **Budget history table**: Last 6 months of spend
- **Content performance table**: Each article with metrics and trends
- **ROI summary**: Comparison to traditional agency costs

### Scheduling

**Recommended**: Sunday 3am weekly via cron or Solid Queue

**Solid Queue example** (add to `config/recurring.yml`):
```yaml
performance_tracking:
  class: SeoAiEngine::PerformanceTrackingJob
  queue: default
  schedule: "0 3 * * 0"  # Sunday 3am
```

**Manual trigger**:
```ruby
SeoAiEngine::PerformanceTrackingJob.perform_now
```

---

## User Story 4: Budget Management

**Goal**: Track API costs, alert at thresholds, enforce rate limits

### Components Implemented

#### 1. BudgetTracking Model (`app/models/seo_ai_engine/budget_tracking.rb`)

Enhanced model with:

**Constants**:
- `BUDGET_TARGET_GBP = 90.0` - Monthly budget target
- `WARNING_THRESHOLD_GBP = 80.0` - Warning alert threshold
- `ALERT_THRESHOLD_GBP = 100.0` - Exceeded alert threshold

**Methods**:
- `within_budget?` - Returns true if under £90
- `alert_threshold?` - Returns :ok, :warning, or :exceeded
- `budget_percentage` - Percentage of budget used
- `savings_vs_agency(agency_cost = 600.0)` - Calculate monthly savings

**Scopes**:
- `current_month` - Get current month's tracking record
- `recent_months(count = 6)` - Get last N months

#### 2. BudgetTracker Service (`app/services/seo_ai_engine/budget_tracker.rb`)

Centralized service for budget management:

**Methods**:
- `record_cost(service:, cost_gbp:)` - Record API costs (:llm, :serpapi, :gsc)
- `record_content_generation` - Increment content pieces counter
- `check_thresholds` - Check budget status
- `current_month_tracking` - Get or create current month record
- `within_serpapi_daily_limit?` - Check if within 3 requests/day
- `within_weekly_generation_limit?` - Check if within 10 drafts/week

**Auto-alerting**: Logs warnings when thresholds are crossed

#### 3. Cost Tracking Integration

**LlmClient** (`app/services/seo_ai_engine/llm_client.rb`):
- `generate_brief`: £0.50 per brief
- `generate_content`: £2.50 per article
- `review_content`: £0.30 per review

**SerpClient** (`app/services/seo_ai_engine/serp_client.rb`):
- `analyze_keyword`: £1.33 per search (£40/month ÷ 30 searches)

#### 4. Budget Enforcement

**OpportunityDiscoveryJob** (`app/jobs/seo_ai_engine/opportunity_discovery_job.rb`):
- Checks daily SerpAPI limit (3 requests/day) before running
- Limits keyword analysis to 3/day
- Re-queues excess requests for next day

**ContentGenerationJob** (`app/jobs/seo_ai_engine/content_generation_job.rb`):
- Checks weekly generation limit (10 drafts/week)
- Postpones generation if limit reached
- Records content generation count

#### 5. Budget Dashboard

Integrated into Performance Dashboard (`/seo_ai/admin/performance`):

- Monthly costs breakdown (LLM, SerpAPI)
- Cost per article average
- Budget progress bar with color-coding:
  - Green: <£80 (ok)
  - Yellow: £80-99 (warning)
  - Red: £100+ (exceeded)
- Alert status indicators
- 6-month budget history table

### Cost Estimates (Mock Mode)

| Operation | Estimated Cost |
|-----------|----------------|
| Brief Generation | £0.50 |
| Content Generation | £2.50 |
| Content Review | £0.30 |
| SerpAPI Search | £1.33 |
| **Total per article** | **~£4.63** |

**Monthly projection** (10 articles):
- LLM: ~£33.00 (10 briefs + 10 articles + 10 reviews)
- SerpAPI: ~£40.00 (30 searches/month)
- **Total: ~£73.00/month** (within £90 budget)

---

## Routes

Added to engine routes (`config/routes.rb`):

```ruby
namespace :admin do
  get "performance", to: "performance#index"
end
```

Access at: `/seo_ai/admin/performance`

---

## Navigation

Updated layout (`app/views/layouts/seo_ai_engine/application.html.erb`):

- Replaced placeholder "Performance (Coming in US3)" with active link
- Navigation: Opportunities | Drafts | Published | **Performance**

---

## Helpers

Added to `ApplicationHelper` (`app/helpers/seo_ai_engine/application_helper.rb`):

- `format_trend(value)` - Format percentage with +/- prefix
- `trend_color(value)` - CSS class for trend color (green/red)
- `budget_progress_color(status)` - CSS class for budget progress bar

---

## Testing

### Manual Testing

```ruby
# Test PerformanceSnapshot
snapshot = SeoAiEngine::PerformanceSnapshot.create!(
  period_start: 1.week.ago.to_date,
  period_end: Date.current,
  impressions: 1000,
  clicks: 50
)
snapshot.calculate_ctr  # => 5.0
snapshot.calculate_traffic_value  # => 125.0

# Test BudgetTracking
budget = SeoAiEngine::BudgetTracker.current_month_tracking
SeoAiEngine::BudgetTracker.record_cost(service: :llm, cost_gbp: 2.50)
SeoAiEngine::BudgetTracker.record_content_generation
budget.reload
budget.total_cost_gbp  # => 2.50
budget.alert_threshold?  # => :ok

# Run PerformanceTrackingJob
SeoAiEngine::PerformanceTrackingJob.perform_now
```

### Access Dashboard

1. Start Rails server: `bin/dev`
2. Navigate to: `http://localhost:3000/seo_ai/admin/performance`
3. View dashboard with mock data

---

## Future Enhancements (Not in Scope)

### Real GSC Integration

Replace mock data in `PerformanceTrackingJob`:

```ruby
def fetch_gsc_article_data(item, period_start, period_end)
  # Real implementation would:
  # 1. Build GSC query with dimension: 'page', filter: item URL
  # 2. Aggregate impressions, clicks, position for date range
  # 3. Handle API rate limits and errors

  # Example using google-apis-webmasters gem:
  # service = Google::Apis::WebmastersV3::SearchConsoleService.new
  # request = Google::Apis::WebmastersV3::SearchAnalyticsQueryRequest.new
  # request.start_date = period_start.to_s
  # request.end_date = period_end.to_s
  # request.dimensions = ['page']
  # request.dimension_filter_groups = [
  #   Google::Apis::WebmastersV3::ApiDimensionFilterGroup.new(
  #     filters: [
  #       Google::Apis::WebmastersV3::ApiDimensionFilter.new(
  #         dimension: 'page',
  #         expression: item.url
  #       )
  #     ]
  #   )
  # ]
  # response = service.query_search_analytics(site_url, request)
  # ...
end
```

### Alert Mailer

Create `AlertMailer` for email notifications:

```ruby
# app/mailers/seo_ai_engine/alert_mailer.rb
class AlertMailer < ApplicationMailer
  def budget_warning(month, cost)
    # Email when approaching £80
  end

  def budget_exceeded(month, cost)
    # Email when exceeding £100
  end

  def api_failure(service, error)
    # Email on API errors
  end
end
```

Integrate in `BudgetTracker#send_alert`.

### Performance Improvements

- Add caching for dashboard metrics
- Optimize N+1 queries with `includes(:performance_snapshots)`
- Add database indexes on `period_end` and `content_item_id`

---

## Summary

✅ **User Story 3 Completed**:
- PerformanceSnapshot model with calculation methods
- PerformanceTrackingJob for weekly GSC tracking (mock mode)
- PerformanceController with ROI dashboard
- Performance views with DaisyUI components
- Route and navigation integration

✅ **User Story 4 Completed**:
- BudgetTracking model with threshold methods
- BudgetTracker service for cost management
- Cost tracking in LlmClient and SerpClient
- Budget enforcement in jobs (rate limiting)
- Budget dashboard integrated into Performance view

**ROI**: £510/month savings vs traditional £600/month agency (assuming £90/month spend)

**Ready for**: Phase 8 (Polish) and final testing
