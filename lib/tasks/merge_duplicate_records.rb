# frozen_string_literal: true

# Merge duplicate records that are invalid due to duplicate normalized columns
# The normalized column is then populated for the primary record

# Classes that will be normalized:
# Normalizable::NORMALIZED_CLASSES_AND_COLUMNS.keys.map do |class_name|
#   children = class_name.singularize.camelize.constantize.reflections.select do |_key, reflection|
#     reflection.class.in?(WHITELISTED_REFLECTION_CLASSES) && !reflection.options[:through]
#   end
#
#   [class_name, children.values.map{ |v| [v.name, v.class.name.split("::").last] }.to_h]
# end.to_h
# =>
# {"Album"=>{:albums_songs=>"HasManyReflection"},
#  "Artist"=>{:albums=>"HasManyReflection", :songs=>"HasManyReflection"},
#  "Broadcast"=>{:playlists=>"HasManyReflection"},
#  "Genre"=>{:songs=>"HasManyReflection"},
#  "Playlist"=>{:playlists_songs=>"HasManyReflection", :playlist_import=>"HasOneReflection"},
#  "RecordLabel"=>{:albums=>"HasManyReflection"},
#  "Song"=>{:playlists_songs=>"HasManyReflection", :albums_songs=>"HasManyReflection"}}

class MergeDuplicateRecords
  attr_reader :klass, :column_name, :normalized_column_name

  WHITELISTED_REFLECTION_CLASSES = [
    ActiveRecord::Reflection::HasManyReflection,
    ActiveRecord::Reflection::HasOneReflection
  ].freeze

  def initialize(klass, column_name, normalized_column_name = nil)
    @klass = klass
    @column_name = column_name
    # All normalized columns are named "normalized_#{column_name}", but can be overridden if necessary:
    @normalized_column_name = normalized_column_name || "#{Normalizable::NORMALIZED_PREFIX}#{column_name}"
  end

  def perform
    unless klass.column_names.include?(normalized_column_name) && klass.column_names.include?(column_name)
      raise "Class #{klass.name} does not have the necessary columns: #{column_name} and #{normalized_column_name}"
    end

    find_possible_duplicate_id_groups.each do |normalized_name, record_ids|
      merge_records(normalized_name, record_ids)
    end
  end

  def update_id_column(record, new_id)
    # Using update_column to bypass validations; some records are no longer valid due to the normalized columns
    record.update_column("#{klass.name.underscore}_id", new_id) # rubocop:disable Rails/SkipsModelValidations
  end

  def update_children(parent_record, new_id)
    klass.reflections.each_value do |reflection|
      next unless reflection.class.in?(WHITELISTED_REFLECTION_CLASSES)
      next if reflection.options[:through]

      Array.wrap(parent_record.send(reflection.name)).each do |child|
        update_id_column(child, new_id)
      end
    end
  end

  # This is redundant, but I wanted to include a sanity check for peace of mind
  def ensure_children_have_correct_id(parent_record, new_id)
    klass.reflections.each_value do |reflection|
      next unless reflection.class.in?(WHITELISTED_REFLECTION_CLASSES)
      next if reflection.options[:through]

      Array.wrap(parent_record.send(reflection.name)).each do |child|
        next if child.send("#{klass.name.underscore}_id") == new_id

        raise <<~ERROR_MSG
          Child record #{child.class.name} #{child.id} has incorrect #{klass.name.underscore}_id: #{child.send("#{klass.name.underscore}_id")}
          Parent record #{parent_record.class.name} #{parent_record.id} has #{klass.name.underscore}_id: #{new_id}
        ERROR_MSG
      end
    end
  end

  def find_possible_duplicate_id_groups
    groups = klass.all.each_with_object(Hash.new { |h, k| h[k] = [] }) do |record, hash|
      existing_name = record.send(column_name)
      normalized_name = Normalizable.normalize_text(existing_name)
      hash[normalized_name] << record.id
    end

    groups.select { |_k, v| v.size > 1 }
  end

  def choose_primary_record(records)
    name_array = records.map { |r| r.send(column_name) }
    best_name = NameFormatter.format_name(name_array)
    records.select { |record| record.send(column_name) == best_name }.first
  end

  def merge_records(normalized_name, record_ids)
    records = klass.find(record_ids)
    primary_record = choose_primary_record(records)
    return unless primary_record

    ActiveRecord::Base.transaction(requires_new: true) do
      records.each do |record|
        next if record.id == primary_record.id

        update_children(record, primary_record.id)
        ensure_children_have_correct_id(primary_record, primary_record.id)
        record.destroy!
      end
      # populate the normalized column for the primary record
      primary_record.send("#{normalized_column_name}=", normalized_name)
      primary_record.save!
    end
  end
end
