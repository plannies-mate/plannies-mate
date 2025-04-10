# frozen_string_literal: true

require 'tilt'
require 'slim'

require_relative '../helpers/application_helper'
require_relative '../models/authority'
require_relative 'generator_base'

# Generates `site_dir#{path_for authority}.html`
class AuthorityGenerator
  extend GeneratorBase
  extend ApplicationHelper

  def self.generate(authority)
    locals = {
      authority: authority,
      title: authority.name,
    }

    locals[:output_file] =
      render_to_file('authority', "authorities/#{authority.short_name}", locals)
    log "Generated authority page for #{authority.name} (#{authority.short_name})"
    locals
  end

  # Generate pages for all authorities
  def self.generate_all
    Authority.active.each do |authority|
      generate(authority)
    end
    log 'Generated all authority pages'
  end
end
