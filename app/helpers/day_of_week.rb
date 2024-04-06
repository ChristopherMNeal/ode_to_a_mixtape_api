# frozen_string_literal: true

class DayOfWeek
  def day_of_week_from_integer(integer)
    Date::DAYNAMES[integer]
  end

  def integer_from_day_of_week(day_name)
    Date::DAYNAMES.index(day_name.capitalize)
  end
end
