# frozen_string_literal: true

class DayOfWeek
  def self.day_of_week_from_integer(integer)
    Date::DAYNAMES[integer]
  end

  def self.find_day_names_in_string(string)
    return unless string.is_a?(String)

    Date::DAYNAMES.select { |day_name| string.downcase.include?(day_name.downcase) }
  end

  def self.integer_from_day_of_week(day_name_string)
    return unless day_name_string.is_a?(String)

    # This shouldn't be necessary anymore:
    day_name = day_name_string.singularize.capitalize
    return unless Date::DAYNAMES.include?(day_name)

    Date::DAYNAMES.index(day_name)
  end
end
