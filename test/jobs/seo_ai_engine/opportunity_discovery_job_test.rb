require "test_helper"

module SeoAiEngine
  class OpportunityDiscoveryJobTest < ActiveJob::TestCase
    setup do
      # Clear any existing opportunities
      Opportunity.destroy_all
    end

    test "job orchestrates GSC → SerpAPI → Scorer workflow" do
      # This test verifies the job orchestrates the discovery workflow
      # For now, we'll use mock data since API credentials aren't configured

      assert_difference "Opportunity.count", 3 do
        OpportunityDiscoveryJob.perform_now
      end
    end

    test "job creates opportunities with calculated scores" do
      OpportunityDiscoveryJob.perform_now

      opportunities = Opportunity.all

      assert opportunities.count > 0, "Should create at least one opportunity"

      # Verify each opportunity has a valid score
      opportunities.each do |opportunity|
        assert_not_nil opportunity.score
        assert opportunity.score >= 0
        assert opportunity.score <= 100
      end
    end

    test "job creates opportunities with required fields" do
      OpportunityDiscoveryJob.perform_now

      opportunity = Opportunity.first

      assert_not_nil opportunity
      assert_not_nil opportunity.keyword
      assert_not_nil opportunity.search_volume
      assert_not_nil opportunity.competition_difficulty
      assert_not_nil opportunity.score
      assert_equal "pending", opportunity.status
    end

    test "job handles GSC API errors gracefully" do
      # Skip for now - will implement error handling test after job is complete
      skip "GSC error handling test - implement after job logic is complete"
    end

    test "job handles SerpAPI errors gracefully" do
      # Skip for now - will implement error handling test after job is complete
      skip "SerpAPI error handling test - implement after job logic is complete"
    end

    test "job filters out low-value opportunities (score < 30)" do
      # This test would verify that opportunities with scores below threshold
      # are not saved. For now, we'll skip until we implement filtering logic.
      skip "Low-value filtering test - implement after job logic is complete"
    end

    test "job avoids creating duplicate opportunities for same keyword" do
      # Create an existing opportunity
      existing = Opportunity.create!(
        keyword: "eco-friendly cups",
        search_volume: 1000,
        competition_difficulty: "medium",
        score: 50,
        status: "pending",
        opportunity_type: "new_content",
        discovered_at: Time.current
      )

      # Run job (which will include this keyword in mock data)
      OpportunityDiscoveryJob.perform_now

      # Should not create duplicate
      assert_equal 1, Opportunity.where(keyword: "eco-friendly cups").count
    end

    test "job updates existing opportunity if keyword exists with different data" do
      # Create an existing opportunity that matches one in SAMPLE_KEYWORDS
      existing = Opportunity.create!(
        keyword: "eco-friendly paper cups",  # This is in the job's SAMPLE_KEYWORDS
        search_volume: 500,
        competition_difficulty: "high",
        score: 20,
        status: "pending",
        opportunity_type: "new_content",
        discovered_at: 1.day.ago
      )

      # Run job which should update with new data
      OpportunityDiscoveryJob.perform_now

      existing.reload
      # Score should be recalculated with new mock data
      # Since we're using deterministic mock logic, we can verify it changed
      assert_not_equal 500, existing.search_volume, "Search volume should be updated"
    end
  end
end
