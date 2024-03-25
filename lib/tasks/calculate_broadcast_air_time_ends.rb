# frozen_string_literal: true

class CalculateBroadcastAirTimeEnds
  def call(station)
    # for each day, find all start times
    [0..6].each do |day|
      daily_broadcasts = station.broadcasts.where(air_day: day, active: true).order(:air_time_start)
      start_times = daily_broadcasts.map(&:air_time_start)

      # strip start times of date information. Not sure if this is needed
      start_times.map! { |time| time.change(year: 2000, month: 1, day: 1) }

      # there might be duplicate start times if the active attribute is lagging
      start_times.uniq.sort.each_with_index do |start_time, index|
      end
    end
  end
end
