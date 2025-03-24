# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../app/controllers/application_controller'

RSpec.describe ApplicationController do
  # Use Rack::Test methods
  include Rack::Test::Methods

  # Define app for Rack::Test
  def app
    described_class
  end

  # Test configuration settings
  describe 'configuration' do
    it 'sets views directory correctly' do
      expected_path = File.expand_path('../../app/views', __dir__)
      expect(app.views).to eq(expected_path)
    end

    it 'disables logging in test environment' do
      expect(app.logging).to be false
    end
  end
end
