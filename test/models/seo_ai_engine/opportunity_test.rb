require "test_helper"

module SeoAiEngine
  class OpportunityTest < ActiveSupport::TestCase
    test "valid opportunity with all required attributes" do
      opportunity = Opportunity.new(
        keyword: "compostable coffee cups",
        opportunity_type: "new_content",
        score: 85,
        search_volume: 1200,
        competition_difficulty: "medium",
        discovered_at: Time.current
      )

      assert opportunity.valid?
    end

    test "requires keyword" do
      opportunity = Opportunity.new(opportunity_type: "new_content", score: 50, discovered_at: Time.current)
      assert_not opportunity.valid?
      assert_includes opportunity.errors[:keyword], "can't be blank"
    end

    test "requires unique keyword" do
      Opportunity.create!(keyword: "eco cups", opportunity_type: "new_content", score: 50, discovered_at: Time.current)

      duplicate = Opportunity.new(keyword: "eco cups", opportunity_type: "new_content", score: 60, discovered_at: Time.current)
      assert_not duplicate.valid?
      assert_includes duplicate.errors[:keyword], "has already been taken"
    end

    test "requires opportunity_type" do
      opportunity = Opportunity.new(keyword: "test", score: 50, discovered_at: Time.current)
      assert_not opportunity.valid?
      assert_includes opportunity.errors[:opportunity_type], "can't be blank"
    end

    test "validates opportunity_type inclusion" do
      opportunity = Opportunity.new(
        keyword: "test",
        opportunity_type: "invalid_type",
        score: 50,
        discovered_at: Time.current
      )
      assert_not opportunity.valid?
      assert_includes opportunity.errors[:opportunity_type], "is not included in the list"
    end

    test "requires score" do
      opportunity = Opportunity.new(keyword: "test", opportunity_type: "new_content", discovered_at: Time.current)
      assert_not opportunity.valid?
      assert_includes opportunity.errors[:score], "can't be blank"
    end

    test "validates score range 0-100" do
      opportunity = Opportunity.new(keyword: "test", opportunity_type: "new_content", score: 150, discovered_at: Time.current)
      assert_not opportunity.valid?

      opportunity.score = -10
      assert_not opportunity.valid?

      opportunity.score = 0
      assert opportunity.valid?

      opportunity.score = 100
      assert opportunity.valid?
    end

    test "requires discovered_at" do
      opportunity = Opportunity.new(keyword: "test", opportunity_type: "new_content", score: 50)
      assert_not opportunity.valid?
      assert_includes opportunity.errors[:discovered_at], "can't be blank"
    end

    test "validates competition_difficulty inclusion" do
      opportunity = Opportunity.new(
        keyword: "test",
        opportunity_type: "new_content",
        score: 50,
        competition_difficulty: "invalid",
        discovered_at: Time.current
      )
      assert_not opportunity.valid?
    end

    test "high_priority scope returns opportunities with score 70-100" do
      high1 = Opportunity.create!(keyword: "high1", opportunity_type: "new_content", score: 85, discovered_at: Time.current)
      high2 = Opportunity.create!(keyword: "high2", opportunity_type: "new_content", score: 70, discovered_at: Time.current)
      medium = Opportunity.create!(keyword: "medium", opportunity_type: "new_content", score: 65, discovered_at: Time.current)

      high_opportunities = Opportunity.high_priority
      assert_includes high_opportunities, high1
      assert_includes high_opportunities, high2
      assert_not_includes high_opportunities, medium
    end

    test "pending scope returns opportunities with pending status" do
      pending = Opportunity.create!(keyword: "pending1", opportunity_type: "new_content", score: 50, discovered_at: Time.current, status: "pending")
      completed = Opportunity.create!(keyword: "completed1", opportunity_type: "new_content", score: 50, discovered_at: Time.current, status: "completed")

      pending_opportunities = Opportunity.pending
      assert_includes pending_opportunities, pending
      assert_not_includes pending_opportunities, completed
    end

    test "recent scope orders by discovered_at descending" do
      old = Opportunity.create!(keyword: "old", opportunity_type: "new_content", score: 50, discovered_at: 2.days.ago)
      new_opp = Opportunity.create!(keyword: "new", opportunity_type: "new_content", score: 50, discovered_at: Time.current)

      recent = Opportunity.recent
      assert_equal new_opp, recent.first
      assert_equal old, recent.last
    end

    test "defaults status to pending" do
      opportunity = Opportunity.create!(keyword: "test", opportunity_type: "new_content", score: 50, discovered_at: Time.current)
      assert_equal "pending", opportunity.status
    end

    test "stores metadata as jsonb" do
      opportunity = Opportunity.create!(
        keyword: "test",
        opportunity_type: "new_content",
        score: 50,
        discovered_at: Time.current,
        metadata: { competitor_urls: [ "https://example.com" ], related_keywords: [ "eco cups", "green cups" ] }
      )

      assert_equal [ "https://example.com" ], opportunity.metadata["competitor_urls"]
      assert_equal [ "eco cups", "green cups" ], opportunity.metadata["related_keywords"]
    end
  end
end
