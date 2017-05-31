require 'securerandom'
require 'json'
require 'active_support/core_ext/hash/keys'

module Apnotic
  NotificationError = Class.new(StandardError)
  class Notification
    InvalidPayloadError = Class.new(NotificationError)
    InvalidHeadersError = Class.new(NotificationError)

    APS_KEYS = %w(alert badge sound category content-available url-args mutable-content).
      map!(&:freeze).freeze

    APNS_HEADERS = %w(apns-id apns-expiration apns-priority apns-topic apns-collapse-id).
      map!(&:freeze).freeze

    attr_writer :body
    attr_accessor :body_hash, :token, :headers
    attr_accessor :apns_id, :expiration, :priority, :topic, :apns_collapse_id

    def initialize(token, payload, headers = nil)
      raise InvalidPayloadError, "missing payload body" if payload.nil?

      @token = token
      prepare_body(payload)
      prepare_headers(headers)
    end

    def body
      (defined?(@body) ? @body : JSON.dump(@body_hash))
    end

    def headers
      @headers.key?('apns-id') ? @headers : @headers.merge('apns-id' => SecureRandom.uuid)
    end

    private

    def prepare_body(payload)
      case payload
      when Hash
        payload.fetch('aps'.freeze) {
          raise InvalidPayloadError, "Missing payload key `aps`"
        }.assert_valid_keys(*APS_KEYS)
        @body_hash = payload
      when String
        @body = payload
      end
    end

    def prepare_headers(headers)
      case headers
      when nil
        @headers = {}
      when String
        return prepare_headers(JSON.parse(headers))
      when Hash
        headers.assert_valid_keys(*APNS_HEADERS)
        @headers = headers.dup
      else
        raise InvalidHeadersError, "invalid input headers class: #{haeders.class}, expecting Hash or String"
      end
    end
  end
end
