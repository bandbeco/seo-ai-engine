require "test_helper"

module SeoAiEngine
  class GscClientTest < ActiveSupport::TestCase
    # Note: These tests will use VCR cassettes to record/replay actual API responses
    # For now, we'll write tests that expect the service interface

    test "initializes with configuration" do
      client = GscClient.new
      assert_not_nil client
    end

    test "search_analytics returns query data" do
      skip "TODO: Add VCR cassette with real GSC API response"

      client = GscClient.new
      results = client.search_analytics(
        start_date: 28.days.ago.to_date,
        end_date: Date.today,
        dimensions: [ "query" ]
      )

      assert results.is_a?(Array)
      assert results.first.key?(:query)
      assert results.first.key?(:impressions)
      assert results.first.key?(:clicks)
      assert results.first.key?(:position)
    end

    test "search_analytics filters by minimum impressions" do
      skip "TODO: Add VCR cassette"

      client = GscClient.new
      results = client.search_analytics(
        start_date: 28.days.ago.to_date,
        end_date: Date.today,
        dimensions: [ "query" ],
        min_impressions: 10
      )

      results.each do |row|
        assert row[:impressions] >= 10, "Expected impressions >= 10, got #{row[:impressions]}"
      end
    end

    test "handles API errors gracefully" do
      skip "TODO: Test error handling when OAuth token invalid"
      # Should raise GscClient::AuthenticationError or similar
    end

    test "excludes branded searches" do
      skip "TODO: Add VCR cassette"

      client = GscClient.new
      results = client.search_analytics(
        start_date: 28.days.ago.to_date,
        end_date: Date.today,
        dimensions: [ "query" ],
        exclude_branded: true
      )

      # Verify no queries contain "afida" (brand name)
      brand_queries = results.select { |r| r[:query].downcase.include?("afida") }
      assert_empty brand_queries, "Branded searches should be excluded"
    end
  end
end
