# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../app/fetchers/scraper_base'
require_relative '../../app/models/http_cache_entry'

RSpec.describe ScraperBase do
  let(:test_class) do
    Class.new do
      extend ApplicationHelper
      extend ScraperBase
    end
  end

  describe '#create_agent' do
    it 'creates a Mechanize agent with standard settings' do
      agent = test_class.create_agent

      expect(agent).to be_a(Mechanize)
      expect(agent.user_agent).to include('Plannies-Mate')
      expect(agent.robots).to eq(:all)
      expect(agent.history.max_size).to eq(1)
    end
  end

  describe '#fetch_page_with_cache' do
    let(:url) { 'https://example.com/test' }
    let(:agent) { instance_double('Mechanize') }
    let(:page) { instance_double('Mechanize::Page') }
    let(:cache_entry) { instance_double('HttpCacheEntry') }

    before do
      allow(test_class).to receive(:create_agent).and_return(agent)
      allow(test_class).to receive(:log)
      allow(test_class).to receive(:force?).and_return(false)
      allow(test_class).to receive(:debug?).and_return(false)
      allow(HttpCacheEntry).to receive(:for_url).with(url).and_return(cache_entry)

      allow(cache_entry).to receive(:stale?).and_return(false)
      allow(cache_entry).to receive(:conditional_headers).and_return({ 'If-None-Match' => 'some-etag' })
      allow(cache_entry).to receive(:update_from_response)

      allow(agent).to receive(:get).and_return(page)
      allow(page).to receive(:code).and_return('200')
      allow(page).to receive(:body).and_return('test content')
      allow(page).to receive(:header).and_return({})
    end

    it 'fetches a page using conditional headers' do
      expect(agent).to receive(:get).with(url, [], nil, { 'If-None-Match' => 'some-etag' })
      result = test_class.fetch_page_with_cache(url, agent: agent)
      expect(result).to eq(page)
    end

    context 'when force is true' do
      before do
        allow(test_class).to receive(:force?).and_return(true)
      end

      it 'does not use conditional headers' do
        expect(agent).to receive(:get).with(url, [], nil, {})
        test_class.fetch_page_with_cache(url, agent: agent)
      end
    end

    context 'when cache entry is stale' do
      before do
        allow(cache_entry).to receive(:stale?).and_return(true)
      end

      it 'does not use conditional headers' do
        expect(agent).to receive(:get).with(url, [], nil, {})
        test_class.fetch_page_with_cache(url, agent: agent)
      end
    end

    context 'when the server returns 304 Not Modified' do
      before do
        allow(page).to receive(:code).and_return('304')
      end

      it 'logs that the content is unchanged and returns nil' do
        expect(test_class).to receive(:log).with(/unchanged/)
        result = test_class.fetch_page_with_cache(url, agent: agent)
        expect(result).to be_nil
      end
    end

    context 'when the server returns a success code' do
      before do
        allow(page).to receive(:code).and_return('200')
      end

      it 'updates the cache entry with response info' do
        expect(cache_entry).to receive(:update_from_response).with(page)
        test_class.fetch_page_with_cache(url, agent: agent)
      end
    end

    context 'when the server returns an error code' do
      before do
        allow(page).to receive(:code).and_return('500')
      end

      it 'raises an error' do
        expect do
          test_class.fetch_page_with_cache(url, agent: agent)
        end.to raise_error(/Unaccepted response code: 500/)
      end
    end

    context 'when the server returns an empty body' do
      before do
        allow(page).to receive(:body).and_return('')
      end

      it 'raises an error' do
        expect do
          test_class.fetch_page_with_cache(url, agent: agent)
        end.to raise_error(/Empty response/)
      end
    end
  end

  describe '#extract_text' do
    it 'strips whitespace and normalizes spacing' do
      node = double('Node', text: "  This   is a \n\n test  string  ")
      expect(test_class.extract_text(node)).to eq('This is a test string')
    end

    it 'handles nil nodes' do
      expect(test_class.extract_text(nil)).to be_nil
    end
  end

  describe '#extract_number' do
    it 'extracts numeric characters' do
      expect(test_class.extract_number('Population: 123,456')).to eq(123_456)
    end

    it 'handles nil inputs' do
      expect(test_class.extract_number(nil)).to be_nil
    end
  end
end
