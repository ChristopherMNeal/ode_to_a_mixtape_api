# frozen_string_literal: true

module FuzzyFinder
  def self.fuzzy_find(klass, column, value, threshold: 0.8)
    check_threshold(threshold)

    constantize_klass(klass).where("similarity(#{column}, ?) > ?", value, threshold)
  end

  # Returns a hash of thresholds and the records that match that threshold, useful for comparing multiple thresholds.
  # It will return records that match the highest threshold first, then the next highest, etc. to show likely matches
  # first, followed by less and less likely matches.
  # For value 'booker t and the mgs', 0.4 threshold is at the low end of usefulness, but does find mostly relevant
  # results; 0.5 threshold finds all relevant results. 0.3 threshold is too low and will return too many results.
  def self.find_across_multiple_thresholds(klass, column, value, low_threshold: 0.4, high_threshold: 1.0, record_count_warning_threshold: 100) # rubocop:disable Metrics, Layout/LineLength
    [low_threshold, high_threshold].each { |t| check_threshold(t) }

    found_record_ids = []
    thresholds = float_to_span_array(low_threshold, high_threshold).sort_by(&:-@)
    thresholds.to_h do |threshold|
      records = fuzzy_find(klass, column, value, threshold:).where.not(id: found_record_ids)
      found_record_ids += records.pluck(:id)
      record_count = records.count if record_count_warning_threshold.positive?
      if record_count && record_count_warning_threshold < record_count
        record_count_warning_threshold_message(threshold, record_count)
        [threshold, []]
      else
        [threshold, records]
      end
    end
  end

  def self.float_to_span_array(float_1, float_2, step: 0.1)
    decimal_places = [float_1, float_2].map { |f| f.to_s.split('.').last.length }.max
    step ||= 1.0 / (10**decimal_places)

    (float_1..float_2).step(step).to_a
                      .map { |f| f.round(decimal_places) }
                      .reject { |f| f > 1.0 }
  end

  def self.constantize_klass(klass)
    klass.is_a?(String) ? klass.constantize : klass
  end

  def self.check_threshold(threshold)
    raise ArgumentError, 'Threshold must be between 0 and 1' if threshold.negative? || threshold > 1
  end

  def self.record_count_warning_threshold_message(threshold, record_count)
    puts "Threshold #{threshold} has #{record_count} records. The search may be too broad." # rubocop:disable Rails/Output
    puts "Rerun search with 'record_count_warning_threshold: 0' to suppress this message." # rubocop:disable Rails/Output
  end
end
