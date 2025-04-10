# frozen_string_literal: true

require 'spec_helper'
require_relative '../../app/generators/authority_generator'

RSpec.describe AuthorityGenerator do
  after(:all) do
    FileUtils.rm_rf(app_helpers.site_dir)
  end

  describe '.generate' do
    it 'generates a page for a single authority' do
      # Get the first authority from the test data
      authority = Authority.active.first
      expect(authority).not_to be_nil

      # Generate the page for this authority
      locals = described_class.generate(authority)
      expect(locals).to be_a(Hash)

      output_file = File.join(app_helpers.site_dir, "authorities/#{authority.short_name}.html")
      expect(File).to exist(output_file)

      # Check content includes authority info
      content = File.read(output_file)
      expect(content).to include(CGI.escape_html(authority.name))
      expect(content).to include(CGI.escape_html(authority.short_name))
    end
  end

  describe '.generate_all' do
    it 'generates pages for all active authorities' do
      described_class.generate_all

      # Check that a page was generated for each authority
      Authority.active.each do |authority|
        output_file = File.join(app_helpers.site_dir, "authorities/#{authority.short_name}.html")
        expect(File).to exist(output_file)
      end
    end
  end
end
