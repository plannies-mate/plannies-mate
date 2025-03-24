# frozen_string_literal: true

require 'tilt'
require 'slim'

require_relative '../helpers/application_helper'
require_relative '../models/authority'
require_relative 'generator_base'

# Generates `site_dir/authorities.html`
class AuthoritiesGenerator
  extend GeneratorBase
  extend ApplicationHelper

  def self.generate
    authorities = Authority.all.sort_by { |a| [a.state || 'ZZZ', a.name.downcase] }
    locals = { authorities: authorities }

    locals[:output_file] =
      render_to_file('authorities', 'authorities', locals)
    log "Generated authorities index page with #{authorities.size} authorities"
    locals
  end
end
