# frozen_string_literal: true

require 'securerandom'
require 'json'
require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/object/with_options'
require 'active_support/core_ext/hash/except'
require 'active_support/core_ext/hash/keys'
require 'active_support/inflector'
require 'active_support/core_ext/string/inflections'

module Apnotic
  NotificationError = Class.new(StandardError)

  class Notification
    InvalidPayloadError = Class.new(NotificationError)
    InvalidHeadersError = Class.new(NotificationError)

    with_options instance_writer: false, instance_predicate: false do |notification|
      notification.class_attribute :aps_keys
      notification.class_attribute :apns_headers
    end

    self.aps_keys     = %w(alert badge sound category content-available url-args mutable-content).freeze
    self.apns_headers = %w(apns-id apns-push-type apns-expiration apns-priority apns-topic apns-collapse-id).freeze

    attr_writer :body
    attr_accessor :token, :headers, :body_hash

    def initialize(token, payload = nil, headers = nil)
      # raise InvalidPayloadError, "missing payload body" if payload.nil?

      @token = token
      prepare_body(payload)
      prepare_headers(headers)
    end

    def body
      defined?(@body) ? @body : JSON.dump(@body_hash)
    end

    def aps
      @body_hash['aps']
    end

    def custom_payload
      @body_hash.except('aps')
    end

    def custom_payload=(value)
      @body_hash.merge!(value)
    end

    aps_keys.each do |aps_key|
      key = aps_key.underscore
      class_eval <<~RUBY, __FILE__, __LINE__ + 1
        def #{key}; aps['#{aps_key}']; end
        def #{key}=(value); aps['#{aps_key}'] = value; end
      RUBY
    end

    apns_headers.each do |apns_header|
      key = apns_header.underscore
      class_eval <<~RUBY, __FILE__, __LINE__ + 1
        def #{key}; headers['#{apns_header}']; end
        def #{key}=(value); headers['#{apns_header}'] = value; end
      RUBY
    end

    alias_method :expiration, :apns_expiration
    alias_method :expiration=, :apns_expiration=

    alias_method :priority, :apns_priority
    alias_method :priority=, :apns_priority=

    alias_method :topic, :apns_topic
    alias_method :topic=, :apns_topic=

    private

    def prepare_body(payload)
      case payload
      when nil
        @body_hash = { 'aps' => {} }
      when Hash
        payload.fetch('aps') {
          raise InvalidPayloadError, "Missing payload key `aps`"
        }.assert_valid_keys(*aps_keys)
        @body_hash = payload
      when String
        @body = payload
      end
    end

    def prepare_headers(headers)
      case headers
      when nil
        @headers = { "apns-id" => SecureRandom.uuid }
      when String
        return prepare_headers(JSON.parse(headers))
      when Hash
        headers.assert_valid_keys(*apns_headers)
        @headers = if headers.key?('apns-id')
          headers.dup
        else
          headers.merge('apns-id' => SecureRandom.uuid)
        end
      else
        raise InvalidHeadersError, "invalid input headers class: #{headers.class}, expecting Hash or String"
      end
    end
  end
end
