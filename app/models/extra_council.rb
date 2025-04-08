# frozen_string_literal: true

class ExtraCouncil
  include ActiveModel::Model
  extend AppHelpersAccessor

  STATES = %w[VIC NSW QLD SA ACT NT WA TAS].freeze

  attr_accessor :state, :name, :url, :population_k

  validates :name, :url, :population_k, presence: true
  validates :state, presence: true, inclusion: { in: STATES }

  def self.data
    @data ||= YAML.load_file(File.join(app_helpers.root_dir, 'config', 'extra_councils.yml'))
  end

  # Returns a hash of available states and the source of the council lists
  #
  # @return [Hash<String,Hash>] Hash of state codes to name and url attributes e.g.
  # {'VIC' => {name: "Some name", url: "https://some.source/page" }, "NSW" => ... }
  def self.states
    data.transform_values { |state_data| state_data['source'] }
  end

  # Returns Authorities we don't or didn't have scrapers for
  #
  # @return [Array<ExtraCouncil>] Array of extra Authorities we don't have in the system (at time of creating the list)
  def self.where(state:)
    (data[state]['councils'] || []).map do |council_data|
      new(
        state: state,
        name: council_data['name'],
        url: council_data['url'],
        population_k: council_data['population_k']
      )
    end
  end

  def issues
    Issue.where('lower(title) LIKE ?', "%#{name.downcase}%")
  end

  def authority
    normalized_input = self.class.normalize_name(name)

    exact_match = Authority.where(state: state, name: name).first
    return exact_match if exact_match

    candidates = Authority.where(state: state)
                          .where('lower(name) LIKE ?', "%#{normalized_input}%")
    candidates.select do |candidate|
      self.class.normalize_name(candidate.name) == normalized_input
    end.min_by do |c|
      [c.name.size, c.name]
    end
  end

  def self.normalize_name(name)
    name.downcase
        .gsub(/\b(city|shire|council|municipality)\b/, '')
        .gsub(/\s+/, ' ')
        .strip
  end
end
