# frozen_string_literal: true

require 'spec_helper'
require_relative '../../app/generators/generator_base'

RSpec.describe GeneratorBase do
  # Create a test class that uses the module
  let(:test_class) do
    Class.new do
      extend GeneratorBase
      extend AppHelpersAccessor

      def self.test_render_method(template_name, output_path, locals = {})
        render_to_file(template_name, output_path, locals)
      end
    end
  end

  describe '.render_template' do
    it 'renders a template with locals' do
      # Prepare test template
      template_dir = File.join(Dir.tmpdir, 'test_templates')
      FileUtils.mkdir_p(template_dir)
      template_path = File.join(template_dir, 'test.html.slim')
      File.write(template_path, "h1 Hello \#{name}!")

      # Set up our test environment
      allow(described_class).to receive(:templates_dir).and_return(template_dir)

      # Test rendering
      result = described_class.render_template('test', name: 'World')
      expect(result).to include('<h1>Hello World!</h1>')

      # Clean up
      FileUtils.rm_rf(template_dir)
    end
  end

  describe '#render_to_file' do
    let(:test_templates_dir) { File.join(Dir.tmpdir, 'test_templates') }
    let(:test_site_dir) { File.join(Dir.tmpdir, 'test_site') }
    let(:template_content) { "h1 Hello \#{name}!" }
    let(:layout_content) do
      <<~LAYOUT
        doctype html
        html
          head
            title \#{title}
          body
            == yield
      LAYOUT
    end

    before do
      # Set up test directories and files
      FileUtils.mkdir_p(test_templates_dir)
      FileUtils.mkdir_p(test_site_dir)
      
      # Create test template
      File.write(File.join(test_templates_dir, 'test.html.slim'), template_content)
      
      # Create test layout
      File.write(File.join(test_templates_dir, 'layout.html.slim'), layout_content)
      
      # Configure the module to use our test directories
      allow(test_class).to receive(:templates_dir).and_return(test_templates_dir)
      allow(test_class).to receive(:site_dir).and_return(test_site_dir)
      
      # Let the real log method run - we want to test it
      allow(test_class).to receive(:log).and_call_through
    end

    after do
      # Clean up test directories
      FileUtils.rm_rf(test_templates_dir)
      FileUtils.rm_rf(test_site_dir)
    end

    it 'renders the template with layout and writes to file' do
      output_path = test_class.test_render_method('test', 'output', name: 'World', title: 'Test')
      
      # Check file was created
      expect(File.exist?(output_path)).to be true
      
      # Check content includes rendered template with layout
      content = File.read(output_path)
      expect(content).to include('<title>Test</title>')
      expect(content).to include('<h1>Hello World!</h1>')
    end

    it 'creates parent directories as needed' do
      output_path = test_class.test_render_method('test', 'nested/deep/output', name: 'World', title: 'Test')
      
      # Check parent directories were created
      expect(File.directory?(File.join(test_site_dir, 'nested/deep'))).to be true
      
      # Check file was created in the correct location
      expect(File.exist?(output_path)).to be true
    end

    it 'passes custom locals to the template' do
      custom_locals = { name: 'Custom', title: 'Custom Title', extra: 'Extra value' }
      output_path = test_class.test_render_method('test', 'custom', custom_locals)
      
      # Check content includes custom values
      content = File.read(output_path)
      expect(content).to include('<title>Custom Title</title>')
      expect(content).to include('<h1>Hello Custom!</h1>')
    end

    it 'logs the generation' do
      # We need to expect the log call before we invoke the method that will call it
      expect(test_class).to receive(:log).with(/Generated output/)
      
      test_class.test_render_method('test', 'logged_output', name: 'World', title: 'Test')
    end
  end
end
