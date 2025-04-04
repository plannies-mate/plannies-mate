# frozen_string_literal: true

# == Schema Information
#
# Table name: http_cache_entries
#
#  id                     :integer          not null, primary key
#  etag                   :string
#  last_modified_at       :datetime
#  last_not_modified_at   :datetime
#  last_other_response_at :datetime
#  last_success_at        :datetime
#  url                    :string           not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_http_cache_entries_on_url  (url) UNIQUE
#
require_relative '../spec_helper'
require_relative '../../app/models/http_cache_entry'

RSpec.describe HttpCacheEntry do
  describe 'validations' do
    it 'requires a URL' do
      entry = HttpCacheEntry.new
      expect(entry).not_to be_valid
      expect(entry.errors[:url]).to include("can't be blank")
    end

    it 'requires a unique URL' do
      HttpCacheEntry.create!(url: 'https://example.com/test')
      duplicate = HttpCacheEntry.new(url: 'https://example.com/test')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:url]).to include('has already been taken')
    end
  end

  describe '.for_url' do
    it 'finds an existing entry' do
      entry = HttpCacheEntry.create!(url: 'https://example.com/existing')
      found = HttpCacheEntry.for_url('https://example.com/existing')
      expect(found).to eq(entry)
    end

    it 'creates a new entry if none exists' do
      expect do
        HttpCacheEntry.for_url('https://example.com/new')
      end.to change(HttpCacheEntry, :count).by(1)
    end
  end

  describe '#update_from_response' do
    let(:entry) { HttpCacheEntry.create!(url: 'https://example.com/update') }
    let(:response) { double('Mechanize::Page') }

    before do
      allow(response).to receive(:header).and_return({})
      allow(response).to receive(:code).and_return('200')
      allow(Time).to receive(:now).and_return(Time.new(2025, 3, 20))
    end

    it 'updates the etag when it changes' do
      allow(response).to receive(:header).and_return({ 'etag' => 'new-etag' })
      expect do
        entry.update_from_response(response)
      end.to change { entry.reload.etag }.to('new-etag')
    end

    it 'updates the last_modified_at when it changes' do
      modified_time = Time.new(2025, 3, 19).httpdate
      allow(response).to receive(:header).and_return({ 'last-modified' => modified_time })

      expect do
        entry.update_from_response(response)
      end.to(change { entry.reload.last_modified_at })
    end

    it 'updates last_success_at timestamp' do
      expect do
        entry.update_from_response(response)
      end.to(change { entry.reload.last_success_at })
    end
  end

  describe '#conditional_headers' do
    it 'includes If-None-Match when etag is present' do
      entry = HttpCacheEntry.new(url: 'https://example.com', etag: 'test-etag')
      headers = entry.conditional_headers
      expect(headers['If-None-Match']).to eq('test-etag')
    end

    it 'includes If-Modified-Since when last_modified_at is present' do
      time = Time.new(2025, 3, 19)
      entry = HttpCacheEntry.new(url: 'https://example.com', last_modified_at: time)
      headers = entry.conditional_headers
      expect(headers['If-Modified-Since']).to eq(time.httpdate)
    end

    it 'returns empty hash when no cache info is available' do
      entry = HttpCacheEntry.new(url: 'https://example.com')
      expect(entry.conditional_headers).to be_empty
    end
  end

  describe '#stale?' do
    before do
      @now = Time.parse('2025-03-23 10:00:00')
      allow(Time).to receive(:now).and_return(@now)
    end

    it 'returns true when last_success_at is nil' do
      entry = HttpCacheEntry.new(url: 'https://example.com')
      expect(entry.stale?).to be true
    end

    it 'returns true when last_success_at is exactly 7 days ago' do
      exactly_seven_days_ago = @now - 7.days
      entry = HttpCacheEntry.new(url: 'https://example.com', last_success_at: exactly_seven_days_ago)
      expect(entry.stale?).to be true
    end

    it 'returns false when last_success_at is less than 7 days ago' do
      recent_time = @now - 7.days + 5.seconds
      entry = HttpCacheEntry.new(url: 'https://example.com', last_success_at: recent_time)
      expect(entry.stale?).to be false
    end
  end
end
