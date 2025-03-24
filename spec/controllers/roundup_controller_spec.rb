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

  context 'With roundup requested' do
    before do
      app_helpers.roundup_requested = true
    end
    after do
      app_helpers.roundup_requested = false
    end

    it 'GET / returns requested status' do
      expect(app_helpers.roundup_requested?).to eq(true)
      get '/'

      expect(last_response).to be_ok
      body = last_response.body

      expect(body).to include('Roundup HAS been requested')
    end
  end

  context 'Without roundup request' do
    before do
      app_helpers.roundup_requested = false
    end

    it 'GET / returns not requested status' do
      expect(app_helpers.roundup_requested?).to eq(false)
      get '/'

      expect(last_response).to be_ok
      response = last_response.body

      expect(response).to include('Roundup has NOT been requested')
    end

    it 'Updates the request status' do
      expect(app_helpers.roundup_requested?).to eq(false)
      post '/'

      expect(last_response).to be_redirect

      follow_redirect!

      expect(last_response).to be_ok
      response = last_response.body

      expect(response).to include('Roundup HAS been requested')
      expect(app_helpers.roundup_requested?).to eq(true)
    end
  end
end
