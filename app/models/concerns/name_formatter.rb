# frozen_string_literal: true

# This module is used to select the best formatted name from a list of possible names.
# It will prefer names that have the correct small word casing and already have correctly capitalized words.
# It should be used to automate selecting the best name from a list of possible names.
# TODO: Use this module when adding a new artist to select the best formatted name
#   *unless* there's a spotify ID available (or some other indicator that we already have the prefered name)
module NameFormatter
  SMALL_WORDS = %w[a an and as at but by for if in nor of on or so the to up yet].freeze

  def self.format_name(possible_names)
    return possible_names.first if possible_names.size == 1

    # Normalize "&" to "and" to make comparisons fairer. Not sure if this is the best approach.
    possible_names = possible_names.map { |name| name.gsub(/\s*&\s*/, ' and ') }

    formatted_names = possible_names.map { |name| custom_titleize(name) }
    # Sort to prefer the most correctly formatted version
    formatted_names.max_by do |original_name, titleized_name|
      [
        punctuation_and_diacritic_score(original_name), # Prefer names with more punctuation/diacritics
        titleized_name.squeeze(' ') == titleized_name ? 1 : 0, # Prefer names without extra spaces
        SMALL_WORDS.any? { |w| titleized_name.include?(" #{w.capitalize} ") } ? 1 : 0, # Prefer correct small word case
        possible_names.include?(titleized_name) ? 1 : 0 # Prefer names that existed in the original set
      ]
    end.last
  end

  def self.custom_titleize(name)
    words = name.downcase.split
    words.each_with_index.map do |word, index|
      index.zero? || SMALL_WORDS.exclude?(word) ? word.capitalize : word
    end.join(' ')
  end

  # Calculate a score based on the number of punctuation and diacritic characters in the name, excluding ampersands
  # This makes the assumption that names with more punctuation and diacritics are more correct.
  def self.punctuation_and_diacritic_score(name)
    name.chars.count { |char| char.match?(/[^a-zA-Z0-9&\s]/) }
  end
end
#
# # Example usage:
# artist_names = [
#   'Sly And The Family Stone',
#   'Sly and the Family Stone',
#   'Sly and The Family Stone',
#   'Sly & The Family Stone',
#   'Sly & the Family Stone',
#   'sly and the family stone',
#   'sly & the family stone',
#   'sly  and the family stone',
#   'Sly and the family stone',
#   'Sly and the Family stone',
#   'Sly & The family Stone',
#   'Sly & The family stone'
# ]
#
# best_name = NameFormatter.format_name(artist_names)
