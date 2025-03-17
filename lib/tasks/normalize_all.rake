# frozen_string_literal: true

namespace :task do
  desc 'Normalize all Classes with Normalizable module to correct invalid data.'
  task normalize_all: :environment do
    Normalizable::NORMALIZED_CLASSES_AND_COLUMNS.each do |klass, columns|
      model = klass.constantize
      columns.each do |column_name|
        MergeDuplicateRecords.new(model, column_name).perform
      end
    end
  end
end
