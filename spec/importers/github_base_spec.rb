# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../app/importers/github_base'

RSpec.describe GithubBase do
  # Create a test class to use the module
  let(:test_class) { Class.new { extend GithubBase } }

  describe '.create_client' do
    context 'without token' do
      before do
        @prev = ENV.fetch('GITHUB_PERSONAL_TOKEN')
        ENV['GITHUB_PERSONAL_TOKEN'] = nil
      end

      after do
        ENV['GITHUB_PERSONAL_TOKEN'] = @prev
      end

      it 'Throws an error', vcr: { cassette_name: cassette_name('create_client without token') } do
        expect { test_class.create_client }.to raise_error(Octokit::Unauthorized)
      end
    end
  end

  describe '.refresh_at' do
    it 'returns a time one week ago' do
      now = Time.now
      allow(Time).to receive(:now).and_return(now)

      one_week_ago = test_class.refresh_at
      # within an hour and a second when DST changes
      expect(one_week_ago).to be_within(3601).of(now - 7.days)
    end
  end
end
