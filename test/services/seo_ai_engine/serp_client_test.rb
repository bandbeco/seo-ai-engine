require "test_helper"

module SeoAiEngine
  class SerpClientTest < ActiveSupport::TestCase
    setup do
      @client = SerpClient.new
    end

    test "analyze_keyword returns structured SERP data" do
      # Mock data to avoid actual API calls
      keyword = "eco-friendly paper cups"

      result = @client.analyze_keyword(keyword)

      assert_not_nil result
      assert_kind_of Hash, result

      # Check required fields from SERP analysis
      assert_includes result.keys, :keyword
      assert_includes result.keys, :search_volume
      assert_includes result.keys, :competition_difficulty
      assert_includes result.keys, :organic_results
      assert_includes result.keys, :related_questions

      assert_equal keyword, result[:keyword]
    end

    test "analyze_keyword handles search volume data" do
      keyword = "biodegradable straws"

      result = @client.analyze_keyword(keyword)

      assert_not_nil result[:search_volume]
      assert_kind_of Integer, result[:search_volume]
      assert result[:search_volume] >= 0
    end

    test "analyze_keyword determines competition difficulty" do
      keyword = "compostable coffee cups"

      result = @client.analyze_keyword(keyword)

      assert_not_nil result[:competition_difficulty]
      assert_includes [ "low", "medium", "high" ], result[:competition_difficulty]
    end

    test "analyze_keyword returns organic results with positions" do
      keyword = "sustainable packaging"

      result = @client.analyze_keyword(keyword)

      assert_not_nil result[:organic_results]
      assert_kind_of Array, result[:organic_results]
      assert result[:organic_results].length > 0

      # Check first organic result structure
      first_result = result[:organic_results].first
      assert_includes first_result.keys, :position
      assert_includes first_result.keys, :title
      assert_includes first_result.keys, :link
    end

    test "analyze_keyword returns related questions (PAA)" do
      keyword = "recyclable food containers"

      result = @client.analyze_keyword(keyword)

      assert_not_nil result[:related_questions]
      assert_kind_of Array, result[:related_questions]
      # PAA may be empty for some keywords, so just check type
    end

    test "analyze_keyword raises error for empty keyword" do
      assert_raises(ArgumentError) do
        @client.analyze_keyword("")
      end
    end

    test "analyze_keyword raises error for nil keyword" do
      assert_raises(ArgumentError) do
        @client.analyze_keyword(nil)
      end
    end

    test "analyze_keyword handles API errors gracefully" do
      # This test verifies error handling when API fails
      # For now, we'll skip this test until we implement actual API integration
      skip "API error handling test - implement when integrating real SerpAPI"
    end
  end
end
