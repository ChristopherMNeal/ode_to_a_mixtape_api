# frozen_string_literal: true

require Rails.root.join('lib/tasks/merge_duplicate_records')

# This task normalizes all classes with Normalizable module to correct invalid data. It is dependent on the
# MergeDuplicateRecords service object.
# It will need to be run any time the Normalizable module is updated, when new classes are added to the module, or if
# normalizable unique constraints are added to the database.
# Usage: rake task:normalize_all
namespace :task do
  desc 'Normalize all Classes with Normalizable module to correct invalid data.'
  task normalize_all: :environment do
    Normalizable::NORMALIZED_CLASSES_AND_COLUMNS.each do |klass_name, normalizable_hash|
      klass = klass_name.constantize
      normalizable_column = normalizable_hash[:normalizable_column]
      normalizable_column_name = "#{Normalizable::NORMALIZED_PREFIX}#{normalizable_column}"
      MergeDuplicateRecords.new(klass, normalizable_hash).perform
      klass.where(normalizable_column_name => nil).find_each(&:save!)
    end
  end
end
