# frozen_string_literal: true

module Normalizable
  extend ActiveSupport::Concern
  def self.normalize_text(text)
    I18n.transliterate(text.to_s)
        .downcase
        .squeeze(' ')
        .gsub(/\s*&\s*/, ' and ')
        .gsub(' andthe ', ' and the ') # catch one common typo
        .gsub('/w', 'with')
        .gsub('.', '') # remove periods
        .strip
  end

  module ClassMethods
    def normalize_column(source, normalized = nil)
      normalized ||= "#{source}_normalized"
      before_save do
        raw_value = send(source)
        send("#{normalized}=", Normalizable.normalize_text(raw_value)) if raw_value.present?
      end
    end
  end
end
