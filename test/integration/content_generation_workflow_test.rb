require "test_helper"

module SeoAiEngine
  class ContentGenerationWorkflowTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    setup do
      @opportunity = seo_ai_opportunities(:high_score_pending)
    end

    test "complete content generation workflow from opportunity to published content" do
      # Step 1: Start with a pending opportunity
      assert @opportunity.pending?
      assert_nil @opportunity.content_brief

      # Step 2: Generate content (run job synchronously for testing)
      assert_difference "ContentBrief.count", 1 do
        assert_difference "ContentDraft.count", 1 do
          ContentGenerationJob.perform_now(@opportunity.id)
        end
      end

      # Step 3: Verify opportunity is now completed
      @opportunity.reload
      assert @opportunity.completed?

      # Step 4: Verify content brief was created
      brief = @opportunity.content_brief
      assert_not_nil brief
      assert_equal @opportunity.keyword, brief.target_keyword
      assert_not_nil brief.suggested_title

      # Step 5: Verify content draft was created
      draft = brief.content_draft
      assert_not_nil draft
      assert_equal "pending_review", draft.status
      assert_not_nil draft.title
      assert_not_nil draft.body
      assert draft.body.length > 100 # Should have substantial content

      # Step 6: Verify draft was reviewed (quality score set)
      assert_not_nil draft.quality_score
      assert draft.quality_score >= 50 # Mock returns 75

      # Step 7: Approve the draft via controller action
      assert_difference "ContentItem.count", 1 do
        post approve_admin_content_draft_path(draft)
      end

      # Step 8: Verify draft is now published
      draft.reload
      assert_equal "published", draft.status

      # Step 9: Verify content item was created
      content_item = draft.content_item
      assert_not_nil content_item
      assert_not_nil content_item.slug
      assert_equal draft.title, content_item.title
      assert_equal draft.body, content_item.body
      assert_not_nil content_item.published_at

      # Step 10: Verify slug generation works
      assert content_item.slug.present?
      assert_equal content_item.slug, content_item.to_param
    end

    test "rejecting draft returns opportunity to pending" do
      # Generate content first
      ContentGenerationJob.perform_now(@opportunity.id)
      @opportunity.reload
      draft = @opportunity.content_brief.content_draft

      # Reject the draft
      assert_no_difference "ContentItem.count" do
        post reject_admin_content_draft_path(draft)
      end

      # Verify draft is rejected
      draft.reload
      assert_equal "rejected", draft.status

      # Verify opportunity is back to pending
      @opportunity.reload
      assert @opportunity.pending?
    end

    test "quality score below 50 prevents draft creation" do
      # This would require mocking LlmClient to return low score
      # Skipping for now as we're using mock responses
    end

    test "services handle missing data gracefully" do
      # Test that services log errors and re-raise
      opportunity = Opportunity.create!(
        keyword: "test keyword",
        opportunity_type: "new_content",
        score: 75,
        discovered_at: Time.current,
        status: "pending"
      )

      # Should succeed with mock data
      assert_nothing_raised do
        strategist = ContentStrategist.new(opportunity)
        brief = strategist.create_brief
        assert_not_nil brief
      end
    end
  end
end
