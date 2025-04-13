# frozen_string_literal: true

require_relative '../spec_helper'

require 'rack/test'
require_relative '../../app/controllers/roundup_controller'

RSpec.describe RoundupController do
  include Rack::Test::Methods

  def app
    RoundupController
  end

  before do
    # Set the host header for requests
    header 'HOST', '127.0.0.1'
  end

  context 'Without roundup request' do
    before do
      app_helpers.roundup_finished!
      expect(app_helpers.roundup_requested?).to eq(false)
    end

    it 'Updates the request status' do
      expect(app_helpers.roundup_requested?).to eq(false)
      post '/'

      expect(last_response).to be_redirect
      expect(app_helpers.roundup_requested?).to eq(true)
    end

    it 'Updates the request status and redirects to home when no referer' do
      expect(app_helpers.roundup_requested?).to eq(false)
      post '/'

      expect(last_response).to be_redirect
      expect(last_response.location).to eq('http://127.0.0.1/')
    end

    it 'Updates the request status and redirects to referer when present' do
      expect(app_helpers.roundup_requested?).to eq(false)

      # Set referer header to simulate coming from the scrapers page
      header 'REFERER', 'http://127.0.0.1/scrapers'
      post '/'

      expect(last_response).to be_redirect
      expect(last_response.location).to eq('http://127.0.0.1/scrapers')
      expect(app_helpers.roundup_requested?).to eq(true)
    end
  end
end
