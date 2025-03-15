# frozen_string_literal: true

# To do:
#   - deal with "The" at the beginning of titles -- this should happen in a fuzzy matcher
#   - incorporate fuzzy matching to find possible duplicates
#     - "booker t and the mg's" vs "booker t and the mgs"
#   - Create a CSV of fuzzy matches to review?
#   - look up preferred names from Spotify API

# Incorporate fuzzy matching:
# (4..9).map { |threshold| Artist.where("similarity(name, ?) > ?", "booker t and the mgs", (threshold / 10.0)).count }
# For booker t, .4 is at the low end of usefulness, but does find mostly relevant results; .5 finds all relevant results

# This helper class merges records that are invalid due to duplicate normalized columns
# The normalized column is then populated for the primary record
class MergeDuplicateRecords
  attr_reader :model, :column_name, :normalized_column_name

  def initialize(model, column_name, normalized_column_name = nil)
    @model = model
    @column_name = column_name
    # All normalized columns are named "normalized_#{column_name}", but can be overridden if necessary:
    @normalized_column_name = normalized_column_name || "normalized_#{column_name}"
  end

  def perform
    unless model.column_names.include?(normalized_column_name) && model.column_names.include?(column_name)
      raise "Model #{model.name} does not have the necessary columns: #{column_name} and #{normalized_column_name}"
    end

    find_possible_duplicate_id_groups
      .each { |hash| merge_records(hash) }
  end

  def update_id_column(record, new_id)
    # Using update_column to bypass validations; some records are no longer valid due to the normalized columns
    record.update_column("#{model.name.underscore}_id", new_id)
  end

  def update_children(parent_record, new_id)
    model.reflections.each_key do |association_name|
      associated_records = parent_record.send(association_name)

      ActiveRecord::Base.transaction do
        # Check if the association is a collection or a single record
        if associated_records.respond_to?(:each)
          associated_records.each do |record|
            update_id_column(record, new_id)
          end
        else
          update_id_column(associated_records, new_id)
        end
      end
    end
  end

  def find_possible_duplicate_id_groups
    groups = model.all.each_with_object(Hash.new { |h, k| h[k] = [] }) do |record, hash|
      existing_name = record.send(column_name)
      normalized_name = Normalizable.normalize_text(existing_name)
      hash[normalized_name] << record.id
    end

    groups.select { |_k, v| v.size > 1 }
  end

  def choose_primary_record(records, _normalized_column_name)
    Rails.logger.debug 'Select the primary record for the following group:'
    records.each_with_index { |record, index| puts "#{index + 1}. #{record.send(column_name)}" }

    Rails.logger.debug 'Primary record number: '
    primary_record_number = gets.chomp.to_i
    records[primary_record_number - 1]

    # Too tedious to do manually.
    # TODO: Implement NameFormatter to automate selecting the 'best' name for most cases.
    # NameFormatter.format_name(records.map(&column_name))
  end

  def merge_records(hash)
    normalized_column_name, id_group = hash
    # prompt user to select the primary record
    records = model.find(id_group)
    primary_record = choose_primary_record(records, normalized_column_name)

    records.each do |record|
      next if record.id == primary_record.id

      update_children(record, primary_record.id)
      record.destroy!
    end
    # populate the normalized column for the primary record
    primary_record.save!
  end
end
