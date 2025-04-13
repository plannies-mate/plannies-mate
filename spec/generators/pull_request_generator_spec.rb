# frozen_string_literal: true

require_relative '../spec_helper'
# require_relative '../lib/generators/pull_request_generator'

RSpec.describe PullRequestGenerator do
  describe '.generate' do
    let(:pull_request1) { instance_double(PullRequest, id: 1, title: 'PR 1') }
    let(:pull_request2) { instance_double(PullRequest, id: 2, title: 'PR 2') }
    let(:output_file1) { 'tmp/html/pull_requests/1.html' }
    let(:output_file2) { 'tmp/html/pull_requests/2.html' }

    before do
      allow(PullRequest).to receive(:find_each).and_yield(pull_request1).and_yield(pull_request2)
      allow(described_class).to receive(:generate_for_pull_request)
        .with(pull_request1).and_return({ output_file: output_file1 })
      allow(described_class).to receive(:generate_for_pull_request)
        .with(pull_request2).and_return({ output_file: output_file2 })
    end

    it 'generates pull request pages for all pull requests' do
      result = described_class.generate

      expect(result[:count]).to eq(2)
      expect(result[:output_files]).to match_array([output_file1, output_file2])
    end
  end

  describe '.generate_for_pull_request' do
    let(:pull_request) { instance_double(PullRequest, id: 1, title: 'Test PR') }
    let(:authority1) { instance_double(Authority, short_name: 'Auth1') }
    let(:authority2) { instance_double(Authority, short_name: 'Auth2') }
    let(:output_file) { 'tmp/html/pull_requests/1.html' }
    let(:locals) do
      {
        pull_request: pull_request,
        authorities: [authority1, authority2],
        title: "Pull Request ##{pull_request.id} - #{pull_request.title}",
      }
    end

    before do
      allow(Authority).to receive(:order).with(:short_name).and_return([authority1, authority2])
      allow(described_class).to receive(:render_to_file)
        .with('pull_request', 'pull_requests/1', locals)
        .and_return(output_file)
      allow(described_class).to receive(:log)
    end

    it 'generates a page for the given pull request' do
      result = described_class.generate_for_pull_request(pull_request)

      expect(result[:pull_request]).to eq(pull_request)
      expect(result[:output_file]).to eq(output_file)
    end

    it 'logs the generation process' do
      expect(described_class).to receive(:log).with('Generated pull request page for #1')
      described_class.generate_for_pull_request(pull_request)
    end
  end
end
