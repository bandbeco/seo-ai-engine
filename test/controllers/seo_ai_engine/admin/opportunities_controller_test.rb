require "test_helper"

module SeoAiEngine
  module Admin
    class OpportunitiesControllerTest < ActionDispatch::IntegrationTest
      include Engine.routes.url_helpers

      setup do
        # Create test opportunities
        @high_priority = Opportunity.create!(
          keyword: "eco cups",
          score: 85,
          search_volume: 5000,
          competition_difficulty: "low",
          opportunity_type: "new_content",
          status: "pending",
          discovered_at: 1.day.ago
        )

        @medium_priority = Opportunity.create!(
          keyword: "biodegradable plates",
          score: 55,
          search_volume: 2000,
          competition_difficulty: "medium",
          opportunity_type: "quick_win",
          status: "pending",
          discovered_at: 2.days.ago
        )

        @dismissed = Opportunity.create!(
          keyword: "compostable forks",
          score: 45,
          search_volume: 1000,
          competition_difficulty: "high",
          opportunity_type: "optimize_existing",
          status: "dismissed",
          discovered_at: 3.days.ago
        )
      end

      # Index action tests
      test "should get index" do
        get admin_opportunities_url
        assert_response :success
      end

      test "index should list all opportunities by default" do
        get admin_opportunities_url
        assert_response :success
        # All opportunities should be shown (3 total)
        assert_select "tbody tr", 3
      end

      test "index should filter by status" do
        get admin_opportunities_url(status: "pending")
        assert_response :success
        # Only pending opportunities (2)
        assert_select "tbody tr", 2
      end

      test "index should filter by min_score" do
        get admin_opportunities_url(min_score: 60)
        assert_response :success
        # Only opportunities with score >= 60 (1)
        assert_select "tbody tr", 1
      end

      test "index should combine filters" do
        get admin_opportunities_url(status: "pending", min_score: 50)
        assert_response :success
        # Pending AND score >= 50 (2)
        assert_select "tbody tr", 2
      end

      test "index should order by score descending" do
        get admin_opportunities_url
        assert_response :success
        # Verify highest score (85) appears first
        assert_select "tbody tr:first-child td:nth-child(2)", text: "eco cups"
      end

      test "index should display opportunity scores with badges" do
        get admin_opportunities_url
        assert_response :success
        # High priority (70+) should have badge
        assert_select ".badge-success", text: /85/
      end

      test "index should show dismiss button for pending opportunities" do
        get admin_opportunities_url
        assert_response :success
        # Should have dismiss buttons (2 pending opportunities)
        assert_select "form[action*='dismiss']", 2
      end

      test "index should not show dismiss button for already dismissed opportunities" do
        get admin_opportunities_url(status: "dismissed")
        assert_response :success
        # Should have no dismiss buttons for dismissed opportunities
        assert_select "form[action*='dismiss']", 0
      end

      # Dismiss action tests
      test "should dismiss opportunity" do
        assert_equal "pending", @high_priority.status

        post dismiss_admin_opportunity_url(@high_priority)
        assert_redirected_to admin_opportunities_url

        @high_priority.reload
        assert_equal "dismissed", @high_priority.status
      end

      test "dismiss should preserve other opportunity attributes" do
        original_score = @high_priority.score
        original_keyword = @high_priority.keyword

        post dismiss_admin_opportunity_url(@high_priority)

        @high_priority.reload
        assert_equal original_score, @high_priority.score
        assert_equal original_keyword, @high_priority.keyword
      end

      test "dismiss should set flash notice" do
        post dismiss_admin_opportunity_url(@high_priority)
        assert_equal "Opportunity dismissed successfully.", flash[:notice]
      end
    end
  end
end
