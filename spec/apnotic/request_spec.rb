require 'spec_helper'

describe Apnotic::Request do
  let(:request) { Apnotic::Request.new(notification) }

  describe ".new" do
    let(:notification) { Apnotic::Notification.new("phone-token") }
    let(:request) { Apnotic::Request.new(notification) }
    let(:headers) { double(:headers) }
    let(:body) { double(:body) }

    before do
      # allow_any_instance_of(Apnotic::Request).to receive(:build_headers_for).with(notification) { headers }
      allow(notification).to receive(:body) { body }
      allow(notification).to receive(:headers) { headers }
    end

    it "initializes a response with the correct attributes" do
      expect(request.path).to eq "/3/device/phone-token"
      expect(request.headers).to eq headers
      expect(request.body).to eq body
    end
  end
end
