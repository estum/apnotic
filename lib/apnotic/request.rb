# frozen_string_literal: true

module Apnotic
  class Request
    attr_reader :path, :headers, :body

    def initialize(notification, token = nil)
      @path    = "/3/device/#{token || notification.token}"
      @headers = notification.headers
      @body    = notification.body
    end

    def encoded_body
      @body.force_encoding(Encoding::BINARY)
    end
  end
end
