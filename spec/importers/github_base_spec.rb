# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../app/importers/github_base'

RSpec.describe GithubBase do
  # Create a test class to use the module
  class TestClass
    extend GithubBase
  end

  describe '.owner' do
    it 'returns the repository owner' do
      expect(TestClass.owner).to eq('planningalerts-scrapers')
    end
  end

  describe '.issues_repo' do
    it 'returns the issues repository name' do
      expect(TestClass.issues_repo).to eq('issues')
    end
  end

  describe '.create_client' do
    context 'with token in ENV' do
      before do
        allow(ENV).to receive(:fetch).with('GITHUB_PERSONAL_TOKEN', nil).and_return('test_token')
      end
      
      it 'creates a client with authentication' do
        client = TestClass.create_client
        expect(client).to be_a(Octokit::Client)
        expect(client.access_token).to eq('test_token')
      end
    end
    
    context 'with token in .env file' do
      before do
        allow(ENV).to receive(:fetch).with('GITHUB_PERSONAL_TOKEN', nil).and_return(nil)
        allow(File).to receive(:size?).with('.env').and_return(true)
        allow(File).to receive(:readlines).with('.env').and_return(["GITHUB_PERSONAL_TOKEN=env_token"])
      end
      
      it 'reads token from file' do
        client = TestClass.create_client
        expect(client).to be_a(Octokit::Client)
        expect(client.access_token).to eq('env_token')
      end
    end
    
    context 'without token' do
      before do
        allow(ENV).to receive(:fetch).with('GITHUB_PERSONAL_TOKEN', nil).and_return(nil)
        allow(File).to receive(:size?).with('.env').and_return(nil)
      end
      
      it 'creates unauthenticated client' do
        client = TestClass.create_client
        expect(client).to be_a(Octokit::Client)
        expect(client.access_token).to be_nil
      end
    end
  end

  describe '.refresh_at' do
    it 'returns a time one week ago' do
      now = Time.now
      allow(Time).to receive(:now).and_return(now)
      
      one_week_ago = TestClass.refresh_at
      expect(one_week_ago).to be_within(1).of(now - 7.days)
    end
  end
end
