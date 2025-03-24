# frozen_string_literal: true

require_relative '../lib/app_helpers_accessor'

# Service class for matching issues to authorities using fuzzy matching
class IssueAuthorityMatcher
  include AppHelpersAccessor

  MORPH_IO_SCRAPERS_URL = 'https://morph.io/planningalerts-scrapers/'
  # Common words that should be excluded from matching as they appear across many authorities
  COMMON_WORDS = %w[
    custom multiple a an the city council authority local region
    shire town municipality metropolitan district government
    planning department offices administration
    new south wales nsw victoria vic queensland qld western australia wa
    south australia sa northern territory nt tasmania tas
    australian capital territory act
    applications land port development
  ].freeze

  # Find an authority for an issue using fuzzy word matching
  #
  # @param title [String] the issue title to match
  # @param labels [Array<String>] the issue labels that might contain scraper names
  # @return [Authority, nil] the matching authority or nil if no match
  def self.match(title, labels = [], debug: false)
    new(title, labels, debug: debug).match
  end

  def initialize(title, labels = [], debug: false)
    @title = title
    @labels = labels
    @debug = app_helpers.debug? || debug
  end

  def match
    # Use exact name match if it exists
    direct_match = Authority.find_by(name: @title)
    return direct_match if direct_match.present?

    potential_authorities = potential_authorities_from_labels
    if @title.include?('Whitehorse')
      puts "DEBUG: potential_authorities: #{potential_authorities.map(&:short_name).join(', ')}", ''
      puts "DEBUG: labels: #{@labels.sort.to_yaml}", '' if @debug
    end

    keywords = extract_keywords(potential_authorities)

    find_unique_match(keywords)
  end

  private

  def potential_authorities_from_labels
    # Find unique scraper from labels if possible
    morph_urls = @labels.map { |label| "#{MORPH_IO_SCRAPERS_URL}multiple_#{label.downcase}" }
    scrapers = Scraper.where(morph_url: morph_urls)
    scraper = scrapers.first if scrapers.size == 1

    if scraper && !@labels.include?('custom')
      puts "DEBUG: selecting scraper(#{scraper.name}.authorities", '' if @debug
      Authority.where(scraper: scraper)
    elsif @labels.include?('custom') && !scraper
      puts 'DEBUG: selecting custom authority authorities', '' if @debug
      multiple = Scraper.where('morph_url like ?', "#{MORPH_IO_SCRAPERS_URL}multiple_%")
      Authority.where.not(scraper: multiple)
    else
      puts 'DEBUG: selecting all authorities', '' if @debug
      Authority.all
    end
  end

  def find_unique_match(keywords)
    title_words = @title.downcase.scan(/\w+/) - COMMON_WORDS
    return nil if title_words.empty?

    puts "DEBUG: title_words: #{title_words.sort.to_yaml}", '' if @debug

    authorities = title_words.map { |title_word| keywords[title_word] }
                             .flatten
                             .compact
                             .uniq
    if @debug
      puts "DEBUG: authorities matched: #{authorities.map(&:short_name).sort.to_yaml}",
           ''
    end
    authorities.first if authorities.size == 1
  end

  def extract_keywords(authorities)
    keywords = Hash.new { |hash, key| hash[key] = [] }
    authorities.each do |authority|
      extract_authority_words(authority).each do |word|
        keywords[word] << authority
      end
    end
    keywords.delete_if { |word, word_authorities| COMMON_WORDS.include?(word) || word_authorities.size > 1 }
    puts "DEBUG: keywords: #{keywords.keys.sort.to_yaml}", '' if @debug
    keywords
  end

  def extract_authority_words(authority)
    words = []
    words.concat(authority.name.downcase.scan(/\w+/))
    words << authority.scraper.name.downcase
    words.concat(authority.scraper.name.downcase.split('_'))
    words.concat(authority.short_name.downcase.split('_'))
    words.concat(authority.short_name.downcase.scan(/\w+/))
    words.uniq - COMMON_WORDS
  end
end
