# frozen_string_literal: true

require_relative '../spec_helper'
require_relative '../../app/helpers/status_helper'

RSpec.describe StatusHelper do
  let(:class_with_helper) do
    Class.new do
      extend ApplicationHelper
      extend StatusHelper
    end
  end

  let(:var_dir) { '/tmp/test_var_dir' }
  let(:status_file) { File.join(var_dir, 'roundup_status.json') }
  let(:request_file) { File.join(var_dir, 'roundup_request.dat') }

  before do
    allow(class_with_helper).to receive(:var_dir).and_return(var_dir)
    FileUtils.mkdir_p(var_dir)
  end

  after do
    FileUtils.rm_rf(var_dir)
  end

  describe '#roundup_request_file' do
    it 'returns the path to the request file' do
      expect(class_with_helper.roundup_request_file).to eq(request_file)
    end
  end

  describe '#roundup_requested?' do
    context 'when request file exists' do
      before do
        FileUtils.touch(request_file)
      end

      it 'returns true' do
        expect(class_with_helper.roundup_requested?).to be true
      end
    end

    context 'when request file does not exist' do
      it 'returns false' do
        expect(class_with_helper.roundup_requested?).to be false
      end
    end
  end

  describe '#roundup_requested=' do
    context 'when set to true' do
      it 'creates the request file with timestamp' do
        class_with_helper.roundup_requested = true
        expect(File.exist?(request_file)).to be true
        expect(File.read(request_file)).to match(/\d{4}-\d{2}-\d{2}/)
      end
    end

    context 'when set to false' do
      before do
        FileUtils.touch(request_file)
      end

      it 'removes the request file' do
        class_with_helper.roundup_requested = false
        expect(File.exist?(request_file)).to be false
      end
    end
  end

  describe '#time_ago_in_words' do
    let(:now) { Time.new(2025, 3, 15, 12, 0, 0) }

    before do
      allow(Time).to receive(:now).and_return(now)
    end

    it 'returns "just now" for times less than 10 seconds ago' do
      time = now - 5
      expect(class_with_helper.time_ago_in_words(time)).to eq('just now')
    end

    it 'returns minutes for times less than 100 minutes ago' do
      time = now - (15 * 60)
      expect(class_with_helper.time_ago_in_words(time)).to eq('15.0 minutes ago')
    end

    it 'returns hours for times more than 100 minutes ago' do
      time = now - (3 * 3600)
      expect(class_with_helper.time_ago_in_words(time)).to eq('3.0 hours ago')
    end
  end
end
