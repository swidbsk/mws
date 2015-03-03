require_relative '../../helpers/json_api'
require_relative '../../helpers/auth_filters'
require_relative '../../mutations/websocket_uris/create'

module V1
  class WebsocketUriApi < ::Cuba
    include JsonApi
    include AuthFilters
  end
end

##
# =/v1/websocket_uri
#
V1::WebsocketUriApi.define do

  res.headers['Content-Type'] = 'application/json; charset=utf-8'

  if restricted_access?
    require_valid_token!
    require_permission!(current_user, :read)
  end

  on get do
    on root do

      ttl = 5.minutes
      outcome = WebsocketUris::Create.run(
          user: nil,
          tags: nil,
          ttl: ttl
      )
      if outcome.success?
        websocket_uri = outcome.result
        protocol = ENV['MWS_NO_SSL'] ? "ws" : "wss"
        json = {
            expiresAt: ttl.from_now.utc.iso8601,
            uri: "#{protocol}://#{ENV['APP_DOMAIN']}/?token=#{websocket_uri.socket_id}",
            tags: websocket_uri.tags
        }
        respond_json(200, json)
      else
        respond_json(503, outcome.errors.message)
      end
    end
  end
end