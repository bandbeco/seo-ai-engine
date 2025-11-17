require "google/apis/webmasters_v3"
require "googleauth"

module SeoAiEngine
  class GscClient
    class AuthenticationError < StandardError; end
    class APIError < StandardError; end

    def initialize
      @service = Google::Apis::WebmastersV3::WebmastersService.new
      @service.authorization = authorize
    end

    # Fetches search analytics data from Google Search Console
    def search_analytics(start_date:, end_date:, dimensions: [ "query" ], min_impressions: 10, exclude_branded: true)
      site_url = "sc-domain:afida.com"

      request = Google::Apis::WebmastersV3::SearchAnalyticsQueryRequest.new(
        start_date: start_date.to_s,
        end_date: end_date.to_s,
        dimensions: dimensions,
        row_limit: 1000
      )

      response = @service.query_search_analytics(site_url, request)
      
      # Transform response to our format
      # Google API returns rows with keys array containing dimension values
      results = (response.rows || []).map do |row|
        # For "query" dimension, keys[0] contains the actual search query
        query_text = row.keys&.first
        next if query_text.blank?  # Skip rows with no query
        
        {
          query: query_text,
          impressions: row.impressions.to_i,
          clicks: row.clicks.to_i,
          ctr: row.ctr.to_f,
          position: row.position.to_f
        }
      end.compact  # Remove nil entries

      # Apply filters
      results = results.select { |r| r[:impressions] >= min_impressions } if min_impressions
      results = results.reject { |r| r[:query].downcase.include?("afida") } if exclude_branded

      Rails.logger.info "[GscClient] Found #{results.count} keywords from Search Console"
      results
    rescue Google::Apis::AuthorizationError => e
      Rails.logger.error "[GscClient] Authorization failed: #{e.message}"
      raise AuthenticationError, "Google Search Console authentication failed: #{e.message}"
    rescue Google::Apis::Error => e
      Rails.logger.error "[GscClient] API error: #{e.message}"
      raise APIError, "Google Search Console API error: #{e.message}"
    end

    private

    def authorize
      config = SeoAiEngine.configuration

      # Service account authentication
      if config.google_service_account.present?
        Rails.logger.info "[GscClient] Using service account authentication"
        return Google::Auth::ServiceAccountCredentials.make_creds(
          json_key_io: StringIO.new(config.google_service_account.to_json),
          scope: [ "https://www.googleapis.com/auth/webmasters.readonly" ]
        )
      end

      # No credentials configured
      Rails.logger.warn "[GscClient] No Google credentials configured - using mock data"
      nil
    end
  end
end
