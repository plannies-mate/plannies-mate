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
end
