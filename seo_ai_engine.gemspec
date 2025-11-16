require_relative "lib/seo_ai_engine/version"

Gem::Specification.new do |spec|
  spec.name        = "seo_ai_engine"
  spec.version     = SeoAiEngine::VERSION
  spec.authors     = [ "Laurent Curau" ]
  spec.email       = [ "github@lqro.slmail.me" ]
  spec.homepage    = "https://github.com/bandbeco/shop"
  spec.summary     = "AI-powered SEO content generation and optimization engine"
  spec.description = "Mountable Rails engine that discovers SEO opportunities via Google Search Console and SerpAPI, generates optimized blog content using Claude AI, and tracks performance to replace manual SEO work."

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the "allowed_push_host"
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  spec.metadata["allowed_push_host"] = "https://rubygems.pkg.github.com/bandbeco"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/bandbeco/shop"
  spec.metadata["changelog_uri"] = "https://github.com/bandbeco/shop/blob/main/engines/seo_ai_engine/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "rails", ">= 8.1.1"

  # LLM Integration (Anthropic Claude - can wrap with provider-agnostic layer later)
  spec.add_dependency "anthropic", "~> 1.15"

  # Google Search Console API
  spec.add_dependency "google-apis-webmasters_v3", "~> 0.6"
  spec.add_dependency "googleauth", "~> 1.11"

  # SerpAPI for competitor analysis
  spec.add_dependency "google_search_results", "~> 2.2"
end
