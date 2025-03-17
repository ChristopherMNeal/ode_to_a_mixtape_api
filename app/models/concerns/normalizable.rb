# frozen_string_literal: true

module Normalizable
  extend ActiveSupport::Concern

  NORMALIZED_PREFIX = 'normalized_'
  NORMALIZED_CLASSES_AND_COLUMNS = {
    'Album' => %w[title],
    'Artist' => %w[name],
    'Broadcast' => %w[title],
    'Genre' => %w[name],
    'Playlist' => %w[title],
    'RecordLabel' => %w[name],
    'Song' => %w[title]
  }.freeze

  def self.normalize_text(text)
    I18n.transliterate(text.to_s)
        .downcase
        .squeeze(' ')
        .gsub(/\s*&\s*/, ' and ')
        .gsub(' andthe ', ' and the ') # catch one common typo
        .gsub('/w', 'with') # normalize with shorthand
        .gsub('.', '') # remove periods
        .gsub(',', '') # remove commas
        .strip
  end

  module ClassMethods
    def normalize_column(source, normalized = nil)
      normalized ||= "#{NORMALIZED_PREFIX}#{source}"
      before_save do
        raw_value = send(source)
        send("#{normalized}=", Normalizable.normalize_text(raw_value)) if raw_value.present?
      end
    end
  end
end
