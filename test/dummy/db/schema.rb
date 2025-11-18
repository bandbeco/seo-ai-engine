# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_11_18_210207) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "chats", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "model_id"
    t.datetime "updated_at", null: false
    t.index ["model_id"], name: "index_chats_on_model_id"
  end

  create_table "messages", force: :cascade do |t|
    t.integer "cache_creation_tokens"
    t.integer "cached_tokens"
    t.bigint "chat_id", null: false
    t.text "content"
    t.json "content_raw"
    t.datetime "created_at", null: false
    t.integer "input_tokens"
    t.bigint "model_id"
    t.integer "output_tokens"
    t.string "role", null: false
    t.bigint "tool_call_id"
    t.datetime "updated_at", null: false
    t.index ["chat_id"], name: "index_messages_on_chat_id"
    t.index ["model_id"], name: "index_messages_on_model_id"
    t.index ["role"], name: "index_messages_on_role"
    t.index ["tool_call_id"], name: "index_messages_on_tool_call_id"
  end

  create_table "models", force: :cascade do |t|
    t.jsonb "capabilities", default: []
    t.integer "context_window"
    t.datetime "created_at", null: false
    t.string "family"
    t.date "knowledge_cutoff"
    t.integer "max_output_tokens"
    t.jsonb "metadata", default: {}
    t.jsonb "modalities", default: {}
    t.datetime "model_created_at"
    t.string "model_id", null: false
    t.string "name", null: false
    t.jsonb "pricing", default: {}
    t.string "provider", null: false
    t.datetime "updated_at", null: false
    t.index ["capabilities"], name: "index_models_on_capabilities", using: :gin
    t.index ["family"], name: "index_models_on_family"
    t.index ["modalities"], name: "index_models_on_modalities", using: :gin
    t.index ["provider", "model_id"], name: "index_models_on_provider_and_model_id", unique: true
    t.index ["provider"], name: "index_models_on_provider"
  end

  create_table "seo_ai_budget_trackings", force: :cascade do |t|
    t.decimal "avg_cost_per_piece", precision: 10, scale: 2
    t.integer "content_pieces_generated", default: 0
    t.datetime "created_at", null: false
    t.integer "gsc_requests", default: 0
    t.decimal "llm_cost_gbp", precision: 10, scale: 2, default: "0.0"
    t.integer "llm_requests", default: 0
    t.date "month", null: false
    t.decimal "serpapi_cost_gbp", precision: 10, scale: 2, default: "0.0"
    t.integer "serpapi_requests", default: 0
    t.decimal "total_cost_gbp", precision: 10, scale: 2, default: "0.0"
    t.datetime "updated_at", null: false
    t.index ["month"], name: "index_seo_ai_budget_trackings_on_month", unique: true
  end

  create_table "seo_ai_content_briefs", force: :cascade do |t|
    t.jsonb "competitor_analysis", default: {}
    t.datetime "created_at", null: false
    t.string "created_by_model"
    t.decimal "generation_cost_gbp", precision: 10, scale: 4
    t.jsonb "internal_links", default: {}
    t.jsonb "product_links", default: {}
    t.string "search_intent"
    t.bigint "seo_ai_opportunity_id", null: false
    t.jsonb "suggested_structure", default: {}
    t.string "target_keyword", null: false
    t.datetime "updated_at", null: false
    t.index ["seo_ai_opportunity_id"], name: "index_seo_ai_content_briefs_on_seo_ai_opportunity_id", unique: true
  end

  create_table "seo_ai_content_drafts", force: :cascade do |t|
    t.text "body", null: false
    t.string "content_type", null: false
    t.datetime "created_at", null: false
    t.decimal "generation_cost_gbp", precision: 10, scale: 4
    t.string "meta_description"
    t.string "meta_title"
    t.integer "quality_score"
    t.jsonb "review_notes", default: {}
    t.datetime "reviewed_at"
    t.integer "reviewed_by_id"
    t.string "reviewer_model"
    t.bigint "seo_ai_content_brief_id", null: false
    t.string "status", default: "pending_review", null: false
    t.string "target_keywords", default: [], array: true
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["seo_ai_content_brief_id"], name: "index_seo_ai_content_drafts_on_seo_ai_content_brief_id", unique: true
    t.index ["status", "quality_score"], name: "index_seo_ai_content_drafts_on_status_and_quality_score"
  end

  create_table "seo_ai_content_items", force: :cascade do |t|
    t.string "author_credit", default: "Afida Editorial Team"
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.string "meta_description"
    t.string "meta_title"
    t.datetime "published_at", null: false
    t.integer "related_category_ids", default: [], array: true
    t.integer "related_product_ids", default: [], array: true
    t.bigint "seo_ai_content_draft_id", null: false
    t.string "slug", null: false
    t.string "target_keywords", default: [], array: true
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["published_at"], name: "index_seo_ai_content_items_on_published_at"
    t.index ["seo_ai_content_draft_id"], name: "index_seo_ai_content_items_on_seo_ai_content_draft_id"
    t.index ["slug"], name: "index_seo_ai_content_items_on_slug", unique: true
  end

  create_table "seo_ai_opportunities", force: :cascade do |t|
    t.string "competition_difficulty"
    t.datetime "created_at", null: false
    t.integer "current_position"
    t.datetime "discovered_at", null: false
    t.string "keyword", null: false
    t.jsonb "metadata", default: {}
    t.string "opportunity_type", null: false
    t.integer "score", null: false
    t.integer "search_volume"
    t.string "status", default: "pending", null: false
    t.string "target_url"
    t.datetime "updated_at", null: false
    t.index ["discovered_at"], name: "index_seo_ai_opportunities_on_discovered_at"
    t.index ["keyword"], name: "index_seo_ai_opportunities_on_keyword", unique: true
    t.index ["opportunity_type"], name: "index_seo_ai_opportunities_on_opportunity_type"
    t.index ["score"], name: "index_seo_ai_opportunities_on_score"
    t.index ["status", "score"], name: "index_seo_ai_opportunities_on_status_and_score"
    t.index ["status"], name: "index_seo_ai_opportunities_on_status"
  end

  create_table "seo_ai_performance_snapshots", force: :cascade do |t|
    t.decimal "avg_position", precision: 5, scale: 2
    t.integer "clicks", default: 0
    t.datetime "created_at", null: false
    t.decimal "ctr", precision: 5, scale: 4
    t.integer "impressions", default: 0
    t.jsonb "keyword_positions", default: {}
    t.date "period_end", null: false
    t.date "period_start", null: false
    t.bigint "seo_ai_content_item_id"
    t.decimal "traffic_value_gbp", precision: 10, scale: 2
    t.datetime "updated_at", null: false
    t.index ["period_end"], name: "index_seo_ai_performance_snapshots_on_period_end"
    t.index ["seo_ai_content_item_id", "period_end"], name: "idx_on_seo_ai_content_item_id_period_end_588cc4adf8"
    t.index ["seo_ai_content_item_id"], name: "index_seo_ai_performance_snapshots_on_seo_ai_content_item_id"
  end

  create_table "tool_calls", force: :cascade do |t|
    t.jsonb "arguments", default: {}
    t.datetime "created_at", null: false
    t.bigint "message_id", null: false
    t.string "name", null: false
    t.string "tool_call_id", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id"], name: "index_tool_calls_on_message_id"
    t.index ["name"], name: "index_tool_calls_on_name"
    t.index ["tool_call_id"], name: "index_tool_calls_on_tool_call_id", unique: true
  end

  add_foreign_key "chats", "models"
  add_foreign_key "messages", "chats"
  add_foreign_key "messages", "models"
  add_foreign_key "messages", "tool_calls"
  add_foreign_key "seo_ai_content_briefs", "seo_ai_opportunities"
  add_foreign_key "seo_ai_content_drafts", "seo_ai_content_briefs"
  add_foreign_key "seo_ai_content_items", "seo_ai_content_drafts"
  add_foreign_key "seo_ai_performance_snapshots", "seo_ai_content_items"
  add_foreign_key "tool_calls", "messages"
end
