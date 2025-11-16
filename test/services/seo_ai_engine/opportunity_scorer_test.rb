require "test_helper"

module SeoAiEngine
  class OpportunityScorerTest < ActiveSupport::TestCase
    test "calculates score with all factors present" do
      opportunity_data = {
        search_volume: 1000,
        competition_difficulty: "low",
        product_relevance: 0.8,
        content_gap_score: 0.7
      }

      scorer = OpportunityScorer.new(opportunity_data)
      score = scorer.calculate

      # Score breakdown (out of 100):
      # search_volume: normalized to 40pts max
      # competition (low): 30pts
      # product_relevance (0.8): 16pts (20 * 0.8)
      # content_gap (0.7): 7pts (10 * 0.7)
      # Expected total: ~70-90 range
      assert score >= 0
      assert score <= 100
      assert score.is_a?(Integer)
    end

    test "higher search volume increases score" do
      low_volume = OpportunityScorer.new(
        search_volume: 100,
        competition_difficulty: "medium",
        product_relevance: 0.5,
        content_gap_score: 0.5
      ).calculate

      high_volume = OpportunityScorer.new(
        search_volume: 5000,
        competition_difficulty: "medium",
        product_relevance: 0.5,
        content_gap_score: 0.5
      ).calculate

      assert high_volume > low_volume
    end

    test "lower competition difficulty increases score" do
      low_competition = OpportunityScorer.new(
        search_volume: 1000,
        competition_difficulty: "low",
        product_relevance: 0.5,
        content_gap_score: 0.5
      ).calculate

      high_competition = OpportunityScorer.new(
        search_volume: 1000,
        competition_difficulty: "high",
        product_relevance: 0.5,
        content_gap_score: 0.5
      ).calculate

      assert low_competition > high_competition
    end

    test "competition difficulty scoring: low=30pts, medium=15pts, high=5pts" do
      base_data = { search_volume: 0, product_relevance: 0, content_gap_score: 0 }

      low_score = OpportunityScorer.new(base_data.merge(competition_difficulty: "low")).calculate
      medium_score = OpportunityScorer.new(base_data.merge(competition_difficulty: "medium")).calculate
      high_score = OpportunityScorer.new(base_data.merge(competition_difficulty: "high")).calculate

      # With zero other factors, only competition contributes
      assert_equal 30, low_score
      assert_equal 15, medium_score
      assert_equal 5, high_score
    end

    test "handles missing optional factors gracefully" do
      minimal_data = {
        search_volume: 1000,
        competition_difficulty: "medium"
      }

      scorer = OpportunityScorer.new(minimal_data)
      score = scorer.calculate

      assert score >= 0
      assert score <= 100
    end

    test "product relevance contributes 20% of score" do
      no_relevance = OpportunityScorer.new(
        search_volume: 1000,
        competition_difficulty: "medium",
        product_relevance: 0.0,
        content_gap_score: 0.5
      ).calculate

      full_relevance = OpportunityScorer.new(
        search_volume: 1000,
        competition_difficulty: "medium",
        product_relevance: 1.0,
        content_gap_score: 0.5
      ).calculate

      # Difference should be ~20 points (20% of 100)
      difference = full_relevance - no_relevance
      assert_in_delta 20, difference, 2
    end

    test "content gap contributes 10% of score" do
      no_gap = OpportunityScorer.new(
        search_volume: 1000,
        competition_difficulty: "medium",
        product_relevance: 0.5,
        content_gap_score: 0.0
      ).calculate

      full_gap = OpportunityScorer.new(
        search_volume: 1000,
        competition_difficulty: "medium",
        product_relevance: 0.5,
        content_gap_score: 1.0
      ).calculate

      # Difference should be ~10 points (10% of 100)
      difference = full_gap - no_gap
      assert_in_delta 10, difference, 2
    end

    test "score is always an integer between 0 and 100" do
      100.times do
        random_data = {
          search_volume: rand(0..10000),
          competition_difficulty: [ "low", "medium", "high" ].sample,
          product_relevance: rand(0.0..1.0),
          content_gap_score: rand(0.0..1.0)
        }

        score = OpportunityScorer.new(random_data).calculate

        assert score >= 0, "Score #{score} is below 0"
        assert score <= 100, "Score #{score} is above 100"
        assert score.is_a?(Integer), "Score #{score} is not an integer"
      end
    end
  end
end
