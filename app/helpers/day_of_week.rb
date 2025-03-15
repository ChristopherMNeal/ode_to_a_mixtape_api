# frozen_string_literal: true

class DayOfWeek
  def day_of_week_from_integer(integer)
    Date::DAYNAMES[integer]
  end

  def integer_from_day_of_week(day_name_string)
    return unless day_name_string.is_a?(String)

    day_name = day_name_string.singularize.capitalize
    return unless Date::DAYNAMES.include?(day_name)

    Date::DAYNAMES.index(day_name)
  end
end
