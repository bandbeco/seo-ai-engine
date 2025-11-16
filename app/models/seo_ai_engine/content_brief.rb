module SeoAiEngine
  class ContentBrief < ApplicationRecord
    self.table_name = "seo_ai_content_briefs"

    # Associations
    belongs_to :opportunity, class_name: "SeoAiEngine::Opportunity", foreign_key: "seo_ai_opportunity_id"
    has_one :content_draft, class_name: "SeoAiEngine::ContentDraft", foreign_key: "seo_ai_content_brief_id", dependent: :destroy

    # Validations
    validates :target_keyword, presence: true
    validates :opportunity, presence: true, uniqueness: true
  end
end
