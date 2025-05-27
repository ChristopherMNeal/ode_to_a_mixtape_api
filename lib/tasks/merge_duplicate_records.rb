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
  attr_reader :klass, :column_name, :normalized_column_name, :group_by, :perform_merge

  WHITELISTED_REFLECTION_CLASSES = [
    ActiveRecord::Reflection::HasManyReflection,
    ActiveRecord::Reflection::HasOneReflection
  ].freeze

  def initialize(klass, normalizable_hash)
    @perform_merge = normalizable_hash[:merge_records]
    @klass = klass.instance_of?(Class) ? klass : klass.constantize
    @column_name = normalizable_hash[:normalizable_column]
    @group_by = normalizable_hash[:group_by]
    # All normalized columns are named "normalized_#{column_name}"
    @normalized_column_name = "#{Normalizable::NORMALIZED_PREFIX}#{column_name}"
  end

  def perform # rubocop:disable Metrics/AbcSize
    return unless perform_merge
    unless klass.column_names.include?(normalized_column_name) && klass.column_names.include?(column_name)
      raise "Class #{klass.name} does not have the necessary columns: #{column_name} and #{normalized_column_name}"
    end

    log "Merging duplicate #{klass.name} records with column: #{column_name}"
    log "  Grouped by #{group_by}" if group_by

    id_groups = find_possible_duplicate_id_groups
    # returns a nested array of [normalized_name, [record_id_1, record_id_2, ...]]
    # Using an array instead of a hash to allow for duplicate normalized names when grouping.
    id_groups.each do |normalized_name, record_ids|
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

  def find_duplicate_id_groups(records)
    groups = records.each_with_object(Hash.new { |h, k| h[k] = [] }) do |record, hash|
      existing_name = record.send(column_name)
      normalized_name = Normalizable.normalize_text(existing_name)
      hash[normalized_name] << record.id
    end

    groups.select { |_k, v| v.size > 1 }
  end

  def find_possible_duplicate_id_groups
    records = klass.all
    if group_by.present?
      groups_array = records.group_by { |r| r.send(group_by) }.values.flat_map do |group|
        find_duplicate_id_groups(group)
      end
      groups_array.map(&:to_a).flatten(1)
    else
      find_duplicate_id_groups(records).to_a
    end
  end

  def choose_primary_record(records)
    name_array = records.map { |r| r.send(column_name) }
    best_name = NameFormatter.format_name(name_array)
    records.select { |record| record.send(column_name) == best_name }.first
  end

  def merge_records(normalized_name, record_ids) # rubocop:disable Metrics
    records = klass.where(id: record_ids)
    primary_record = choose_primary_record(records)
    raise "Primary record not found for #{klass.name} with ids: #{record_ids}" unless primary_record

    names = records.map { |r| r.send(column_name) }
    log("Merging #{klass.name} records with columns: #{names.join(', ')} into #{primary_record.send(column_name)}")
    if group_by
      group_by_klass = group_by.gsub('_id', '').camelize.constantize
      group_column_name = if group_by_klass.respond_to?('title')
                            'title'
                          elsif group_by_klass.respond_to?('name')
                            'name'
                          end
      if group_column_name
        primary_group_record = group_by_klass.where(id: primary_record.send(group_by))&.first
        log "  Grouped by #{group_by_klass.name}: #{primary_group_record&.send(group_column_name)}"
      end
    end
    ActiveRecord::Base.transaction(requires_new: true) do
      records.each do |record|
        next if record.id == primary_record.id

        update_children(record, primary_record.id)
        record.destroy!
      end
      # populate the normalized column for the primary record
      primary_record.send("#{normalized_column_name}=", normalized_name)
      primary_record.save!
      log "  Merged #{records.size} records into #{primary_record.send(column_name)}"
    end
  end

  def log(message)
    puts message unless Rails.env.test? # rubocop:disable Rails/Output
  end
end
