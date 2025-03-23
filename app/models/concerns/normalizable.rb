# frozen_string_literal: true

module Normalizable
  extend ActiveSupport::Concern

  NORMALIZED_PREFIX = 'normalized_'
  # These are the classes and columns that will be normalized.
  # Merge records should be applied when the normalized column has a uniqueness constraint.
  # The "group_by" column is used to group records before merging where the uniqueness index is on multiple columns.
  # They are in order of dependency, so that we can merge records in the correct order.
  NORMALIZED_CLASSES_AND_COLUMNS = {
    'Artist' => {
      normalizable_column: 'name',
      merge_records: true
    },
    'Genre' => {
      normalizable_column: 'name',
      merge_records: true
    },
    'RecordLabel' => {
      normalizable_column: 'name',
      merge_records: true
    },
    'Album' => {
      normalizable_column: 'title',
      group_by: 'artist_id',
      merge_records: true
    },
    'Song' => {
      normalizable_column: 'title',
      group_by: 'artist_id',
      merge_records: true
    },
    'Broadcast' => {
      normalizable_column: 'title',
      merge_records: false
    },
    'Playlist' => {
      normalizable_column: 'title',
      merge_records: false
    }
  }.freeze

  def self.normalize_text(text) # rubocop:disable Metrics/MethodLength
    return if text.nil?

    # Would it make sense to create different strategies for different classes? (e.g. Artist vs. Song)
    # We'll see if this is necessary as we go along.
    normalized_text = I18n.transliterate(text.to_s)
                          .downcase
                          .gsub('&', 'and')
                          .gsub(' andthe ', ' and the ') # catch one common typo
                          .gsub('w/', 'with') # normalize with shorthand
                          .gsub(/[.,']/, '') # remove periods, commas, and apostrophes
                          # normalize featuring shorthand (after removing periods, with space before and after)
                          .gsub(' feat ', ' featuring ')
                          .squeeze(' ')
                          .strip

    # Some columns normalize to empty strings, so we should return the original text in that case.
    # This is to avoid uniqueness validation errors when the normalized column is required.
    return text if normalized_text.empty?

    normalized_text
  end

  module ClassMethods
    def normalize_column(source, normalized = nil)
      normalized ||= "#{NORMALIZED_PREFIX}#{source}"
      before_validation do
        raw_value = send(source)
        normalized_value = Normalizable.normalize_text(raw_value)

        send("#{normalized}=", normalized_value)
      end
    end

    def find_or_create_by_normalized_column(normalizable_column: nil, value: nil, group_by_value: nil) # rubocop:disable Metrics
      raise 'normalizable_column is required' if normalizable_column.nil?
      raise 'value is required' if value.nil?

      config = NORMALIZED_CLASSES_AND_COLUMNS[name]
      group_by_column = config[:group_by]
      normalized_column = "#{NORMALIZED_PREFIX}#{normalizable_column}"
      normalized_value = Normalizable.normalize_text(value)

      if group_by_column && group_by_value.nil?
        raise "Group by value for #{group_by_column} is required for #{self.class.name}"
      end

      record = if group_by_column && group_by_value
                 find_by(normalized_column => normalized_value, group_by_column => group_by_value) ||
                   create!(normalizable_column => value, group_by_column => group_by_value)
               else
                 find_by(normalized_column => normalized_value) ||
                   create!(normalizable_column => value)
               end
      best_record_name = NameFormatter.format_name([value, record.send(normalizable_column)])
      record.update!(normalizable_column => best_record_name) if record.send(normalizable_column) != best_record_name

      record
    end
  end
end
