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
      
      results = (response.rows || []).map do |row|
        {
          query: row.keys.first,
          impressions: row.impressions.to_i,
          clicks: row.clicks.to_i,
          ctr: row.ctr.to_f,
          position: row.position.to_f
        }
      end

      # Apply filters
      results = results.select { |r| r[:impressions] >= min_impressions } if min_impressions
      results = results.reject { |r| r[:query].downcase.include?("afida") } if exclude_branded

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

      # Try service account first (recommended)
      if config.google_service_account.present?
        Rails.logger.info "[GscClient] Using service account authentication"
        return Google::Auth::ServiceAccountCredentials.make_creds(
          json_key_io: StringIO.new(config.google_service_account.to_json),
          scope: [ "https://www.googleapis.com/auth/webmasters.readonly" ]
        )
      end

      # Fallback to OAuth if configured (legacy)
      if config.google_oauth_refresh_token.present?
        Rails.logger.info "[GscClient] Using OAuth refresh token authentication"
        return Google::Auth::UserRefreshCredentials.new(
          client_id: config.google_oauth_client_id,
          client_secret: config.google_oauth_client_secret,
          scope: [ "https://www.googleapis.com/auth/webmasters.readonly" ],
          refresh_token: config.google_oauth_refresh_token
        )
      end

      # No credentials configured
      Rails.logger.warn "[GscClient] No Google credentials configured - using mock data"
      nil
    end
  end
end
