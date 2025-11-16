require "test_helper"

module SeoAiEngine
  class ContentBriefTest < ActiveSupport::TestCase
    test "should require opportunity_id and target_keyword" do
      brief = ContentBrief.new
      assert_not brief.valid?
    end

    test "should be valid with required attributes" do
      opportunity = Opportunity.create!(
        keyword: "eco cups",
        opportunity_type: "new_content",
        score: 75,
        discovered_at: Time.current
      )

      brief = ContentBrief.new(
        opportunity: opportunity,
        target_keyword: "eco-friendly coffee cups"
      )
      assert brief.valid?
    end

    test "should store JSONB fields" do
      opportunity = Opportunity.create!(
        keyword: "eco cups",
        opportunity_type: "new_content",
        score: 75,
        discovered_at: Time.current
      )

      brief = ContentBrief.create!(
        opportunity: opportunity,
        target_keyword: "eco-friendly coffee cups",
        suggested_structure: { sections: [ "intro", "body" ] },
        competitor_analysis: { top_sites: [ "example.com" ] },
        product_links: { primary: [ 1, 2 ] }
      )

      brief.reload
      assert_equal({ "sections" => [ "intro", "body" ] }, brief.suggested_structure)
      assert_equal({ "top_sites" => [ "example.com" ] }, brief.competitor_analysis)
      assert_equal({ "primary" => [ 1, 2 ] }, brief.product_links)
    end

    test "should enforce uniqueness on opportunity" do
      opportunity = Opportunity.create!(
        keyword: "eco cups",
        opportunity_type: "new_content",
        score: 75,
        discovered_at: Time.current
      )

      ContentBrief.create!(opportunity: opportunity, target_keyword: "first")
      duplicate = ContentBrief.new(opportunity: opportunity, target_keyword: "second")

      assert_not duplicate.valid?
    end
  end
end
