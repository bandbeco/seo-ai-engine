module SeoAiEngine
  class GscClient
    class AuthenticationError < StandardError; end
    class APIError < StandardError; end

    def initialize
      # OAuth setup deferred until credentials are configured
      # Will require google/apis/webmasters_v3 when needed
    end

    # Fetches search analytics data from Google Search Console
    #
    # @param start_date [Date] Start date for the query
    # @param end_date [Date] End date for the query
    # @param dimensions [Array<String>] Dimensions to group by (e.g., ["query", "page"])
    # @param min_impressions [Integer] Minimum impressions filter
    # @param exclude_branded [Boolean] Exclude queries containing brand name
    # @return [Array<Hash>] Search analytics data
    def search_analytics(start_date:, end_date:, dimensions: [ "query" ], min_impressions: nil, exclude_branded: false)
      # TODO: Implement actual GSC API call
      # For now, return empty array (will be implemented when we have OAuth credentials)
      []
    rescue Google::Apis::AuthorizationError => e
      handle_oauth_expiration(e)
      raise AuthenticationError, "Google Search Console authentication failed: #{e.message}"
    rescue Google::Apis::Error => e
      raise APIError, "Google Search Console API error: #{e.message}"
    end

    private

    def authorize
      # TODO: Implement OAuth 2.0 authorization
      # For now, return nil (tests will be skipped until OAuth is configured)
      #
      # Will use:
      # - SeoAiEngine.configuration.google_oauth_client_id
      # - SeoAiEngine.configuration.google_oauth_client_secret
      # - SeoAiEngine.configuration.google_oauth_refresh_token
      nil
    end

    # Handle OAuth token expiration
    # Logs error with detailed instructions for re-authorization
    # In production, should also:
    # - Send alert email to admin
    # - Pause discovery jobs until re-authorization
    # - Display warning in admin dashboard
    #
    # @param error [Google::Apis::AuthorizationError] The authorization error
    def handle_oauth_expiration(error)
      Rails.logger.error <<~ERROR
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        Google Search Console OAuth Token Expired
        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

        The OAuth refresh token for Google Search Console has expired or been revoked.

        Error: #{error.message}

        REQUIRED ACTIONS:

        1. Re-authorize the application with Google Search Console:
           - Visit Google Cloud Console: https://console.cloud.google.com
           - Navigate to APIs & Services > Credentials
           - Create new OAuth 2.0 credentials or refresh existing ones

        2. Update Rails credentials with new token:
           rails credentials:edit

           Add/update:
           google:
             oauth_client_id: YOUR_CLIENT_ID
             oauth_client_secret: YOUR_CLIENT_SECRET
             oauth_refresh_token: YOUR_NEW_REFRESH_TOKEN

        3. Restart the application to load new credentials

        IMPACT:

        - Keyword discovery jobs will fail until re-authorization
        - Performance tracking will not update
        - Admin dashboard may show stale data

        TODO FOR PRODUCTION:
        - Implement email alert to admin
        - Pause discovery scheduler
        - Display warning banner in admin dashboard

        ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      ERROR

      # TODO: Send email alert
      # AdminMailer.oauth_expired_alert(error).deliver_later

      # TODO: Pause discovery scheduler
      # SeoAiEngine::OpportunityDiscovery.pause_discovery!
    end
  end
end
