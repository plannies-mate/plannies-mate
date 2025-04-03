# frozen_string_literal: true

require_relative '../spec_helper'
require 'rack/test'
require_relative '../../app/controllers/develop_controller'

RSpec.describe DevelopController do
  include Rack::Test::Methods

  def app
    DevelopController
  end

  before do
    # Set the host header for requests
    header 'HOST', '127.0.0.1'
  end

  describe 'GET /debug' do
    it 'returns debug information' do
      get '/debug'

      expect(last_response).to be_ok
      body = last_response.body

      expect(body).to include('test', 'roundup_request_file', 'roundup_request_file_exists')
    end
  end
end
