# SEO AI Engine

A Rails engine for automated SEO opportunity discovery and content generation using AI.

## Features

### User Story 1: Opportunity Discovery ✅

- **Automated Discovery**: Daily job discovers high-value SEO opportunities from Google Search Console
- **SERP Analysis**: Analyzes search results using SerpAPI to determine competition and search volume
- **Smart Scoring**: Scores opportunities 0-100 based on search volume (40%), competition (30%), relevance (20%), and content gap (10%)
- **Admin Dashboard**: View, filter, and manage opportunities at `/ai-seo/admin/opportunities`

### User Story 2: Content Generation ✅

- **AI Content Strategy**: ContentStrategist creates comprehensive content briefs with H2 suggestions, word targets, and key points
- **AI Writing**: ContentWriter generates 1,500-word SEO-optimized articles with markdown formatting
- **Quality Review**: ContentReviewer scores drafts (0-100) and provides actionable feedback
- **Approval Workflow**: Admins review drafts with quality scores before publishing
- **Published Content**: Approved drafts become ContentItems with SEO-friendly slugs
- **Mock Mode**: Development mode uses realistic mock responses (no API key required)

## Installation

Add this engine to your Gemfile:

```ruby
gem 'seo_ai_engine', path: 'engines/seo_ai_engine'
```

Mount the engine in `config/routes.rb`:

```ruby
mount SeoAiEngine::Engine, at: "/seo_ai"
```

Run migrations:

```bash
rails seo_ai_engine:install:migrations
rails db:migrate
```

## Configuration

### API Credentials

The engine requires API credentials for:
- Google Search Console (OAuth 2.0)
- SerpAPI
- Anthropic Claude API

Configure credentials in `config/credentials.yml.enc`:

```yaml
google:
  oauth_client_id: YOUR_CLIENT_ID
  oauth_client_secret: YOUR_CLIENT_SECRET
  oauth_refresh_token: YOUR_REFRESH_TOKEN

serpapi:
  api_key: YOUR_SERPAPI_KEY

anthropic:
  api_key: YOUR_ANTHROPIC_KEY
```

Edit credentials:

```bash
rails credentials:edit
```

### Solid Queue Configuration (Rails 8)

This engine uses background jobs that run via Solid Queue (Rails 8 default).

#### Job Monitoring Dashboard

Rails 8 provides a built-in job monitoring interface via Solid Queue:

**Access the dashboard:**

```
http://localhost:3000/jobs
```

**Features:**
- View all queued, running, and completed jobs
- Monitor job execution times and status
- Inspect failed jobs and error messages
- Retry failed jobs manually

**Key Jobs to Monitor:**
- `SeoAiEngine::OpportunityDiscoveryJob` - Daily keyword discovery
- `SeoAiEngine::ContentGenerationJob` - Content creation workflow
- `SeoAiEngine::PerformanceTrackingJob` - Performance monitoring

**Tip**: Add a link to the job dashboard in your admin navigation for easy access.

## Scheduling OpportunityDiscoveryJob

The `OpportunityDiscoveryJob` discovers SEO opportunities by:
1. Fetching keywords from Google Search Console
2. Analyzing each keyword with SerpAPI
3. Scoring opportunities with OpportunityScorer
4. Saving high-value opportunities (score >= 30)

### Option 1: Using Solid Queue Recurring Tasks (Recommended)

Add to `config/recurring.yml`:

```yaml
# Daily SEO opportunity discovery at 3:00 AM
seo_opportunity_discovery:
  class: SeoAiEngine::OpportunityDiscoveryJob
  schedule: "0 3 * * *"  # Cron syntax: daily at 3am
  queue: default
```

### Option 2: Using whenever gem

Add to `config/schedule.rb`:

```ruby
every 1.day, at: '3:00 am' do
  runner "SeoAiEngine::OpportunityDiscoveryJob.perform_later"
end
```

Then update crontab:

```bash
whenever --update-crontab
```

### Option 3: Manual Execution

Run the job manually via Rails console:

```ruby
# Immediate execution (synchronous)
SeoAiEngine::OpportunityDiscoveryJob.perform_now

# Queue for background execution (asynchronous)
SeoAiEngine::OpportunityDiscoveryJob.perform_later
```

Or via Rails runner:

```bash
# Run immediately
rails runner "SeoAiEngine::OpportunityDiscoveryJob.perform_now"

# Queue for background processing
rails runner "SeoAiEngine::OpportunityDiscoveryJob.perform_later"
```

## Usage

### Content Generation Workflow (User Story 2)

The complete workflow from opportunity to published content:

1. **Discover Opportunities** (`/ai-seo/admin/opportunities`)
   - View SEO opportunities with scores 0-100
   - Filter by status, minimum score
   - Pending opportunities show "Generate Content" button

2. **Generate Content** (Click button)
   - ContentGenerationJob runs 3-stage workflow:
     - **Stage 1**: ContentStrategist creates brief with H2 suggestions
     - **Stage 2**: ContentWriter generates 1,500-word article
     - **Stage 3**: ContentReviewer scores quality and provides feedback
   - Opportunity status: pending → in_progress → completed

3. **Review Draft** (`/ai-seo/admin/content_drafts`)
   - View pending drafts sorted by quality score
   - Review article content with markdown preview
   - Check quality score (must be >= 50)
   - Read AI review notes (strengths & improvements)

4. **Approve or Reject**
   - **Approve**: Creates ContentItem, marks draft as published
   - **Reject**: Resets opportunity to pending for retry

5. **View Published** (`/ai-seo/admin/content_items`)
   - Browse published content cards
   - View full content with SEO metadata
   - See publication details and source opportunity

### Viewing Opportunities

Navigate to the admin dashboard:

```
http://localhost:3000/ai-seo/admin/opportunities
```

Features:
- **Filter by status**: pending, in_progress, completed, dismissed
- **Filter by minimum score**: only show opportunities above threshold
- **Sort by score**: highest priority opportunities first
- **Dismiss irrelevant**: mark opportunities as dismissed
- **Generate content**: One-click content generation for pending opportunities

### Opportunity Scoring

Opportunities are scored 0-100 based on:

| Factor | Weight | Description |
|--------|--------|-------------|
| Search Volume | 40% | Monthly search volume (logarithmic scale) |
| Competition | 30% | Difficulty (low=30pts, medium=15pts, high=5pts) |
| Product Relevance | 20% | How well keyword matches product catalog |
| Content Gap | 10% | Opportunity to improve ranking |

**Score Ranges:**
- **70-100** (High Priority): Green badge - immediate action
- **50-69** (Medium Priority): Yellow badge - good opportunity
- **0-49** (Low Priority): Gray badge - consider for later
- **<30**: Automatically filtered out

### API Integration Status

- **GscClient**: OAuth skeleton implemented, awaiting credentials
- **SerpClient**: Mock implementation (returns deterministic test data)
- **OpportunityScorer**: Fully implemented and tested

## Testing

Run all tests:

```bash
rails test
```

Run specific test suites:

```bash
# Model tests
rails test test/models/seo_ai_engine/opportunity_test.rb

# Service tests
rails test test/services/seo_ai_engine/

# Job tests
rails test test/jobs/seo_ai_engine/

# Controller tests
rails test test/controllers/seo_ai_engine/admin/
```

## Development Roadmap

### ✅ Completed (User Story 1)

- [x] Opportunity model with validations and scopes
- [x] OpportunityScorer service (scoring algorithm)
- [x] GscClient service (skeleton)
- [x] SerpClient service (mock implementation)
- [x] OpportunityDiscoveryJob (orchestration)
- [x] Admin::OpportunitiesController (index, dismiss)
- [x] Admin dashboard views with DaisyUI
- [x] Engine routes and configuration

### ✅ Completed (User Story 2)

- [x] ContentBrief model with JSONB structure
- [x] ContentDraft model with quality validation (score >= 50)
- [x] ContentItem model with slug generation
- [x] PerformanceSnapshot model (ready for US3)
- [x] BudgetTracking model
- [x] LlmClient service (mock mode for development)
- [x] ContentStrategist service (creates content briefs)
- [x] ContentWriter service (generates 1,500-word articles)
- [x] ContentReviewer service (quality scoring)
- [x] ContentGenerationJob (3-stage workflow: Brief → Draft → Review)
- [x] Admin::ContentDraftsController (review, approve, reject)
- [x] Admin::ContentItemsController (view published content)
- [x] Admin dashboard views with DaisyUI
- [x] Integration test for full workflow

### 🔜 Future (User Stories 3-4)

- [ ] Performance tracking with GSC integration
- [ ] ROI dashboard vs £600 agency baseline
- [ ] Budget tracking and API cost management
- [ ] Alert system for budget thresholds

## Architecture

### Services

- **GscClient**: Fetches keywords from Google Search Console
- **SerpClient**: Analyzes SERP results via SerpAPI
- **OpportunityScorer**: Calculates opportunity scores (0-100)

### Jobs

- **OpportunityDiscoveryJob**: Daily discovery workflow (GSC → SerpAPI → Scorer → DB)

### Models

- **Opportunity**: SEO opportunities with scoring and status tracking

### Controllers

- **Admin::OpportunitiesController**: Admin dashboard for opportunity management

## License

Copyright © 2025 Afida. All rights reserved.
