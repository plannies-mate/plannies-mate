# frozen_string_literal: true

require_relative '../spec_helper'
require 'rack/test'
require_relative '../../app/controllers/health_controller'

RSpec.describe HealthController do
  include Rack::Test::Methods

  def app
    HealthController
  end

  before do
    # Set the host header for requests
    header 'HOST', '127.0.0.1'
  end

  describe 'GET /' do
    it 'returns OK' do
      get '/'

      expect(last_response).to be_ok
      expect(last_response.body).to eq('OK')
    end
  end
end
