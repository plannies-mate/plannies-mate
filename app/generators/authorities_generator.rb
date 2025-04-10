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

  def self.generate_existing
    authorities = Authority.active.sort_by do |a|
      [a.broken_score&.positive? ? -a.broken_score : 0, a.state, a.name.downcase]
    end
    locals = { authorities: authorities }

    locals[:output_file] =
      render_to_file('authorities', 'authorities', locals)
    log "Generated authorities index page with #{authorities.size} authorities"
    locals
  end

  def self.generate_extra_councils
    councils_by_state = {}
    states = ExtraCouncil.states
    states.each_key do |state|
      councils_by_state[state] =
        ExtraCouncil.where(state: state)
                    .sort_by { |c| c.name.downcase }
                    .reject(&:authority)
    end
    pops = councils_by_state.values.map { |cs| cs.map(&:population_k) }.flatten.compact.sort
    # highlight the top 10%
    significant_population_k = pops.empty? ? 0 : pops[(pops.size * 0.9).to_i]
    puts "Highlighting pop >= #{significant_population_k} K"
    locals = { states: states, councils_by_state: councils_by_state,
               significant_population_k: significant_population_k, }

    locals[:output_file] =
      render_to_file('extra_councils', 'extra-councils', locals)
    log "Generated extra_councils page for #{states.keys.join(', ')} states"
    locals
  end
end
