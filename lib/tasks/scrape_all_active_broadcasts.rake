# frozen_string_literal: true

require './lib/tasks/scrape_broadcasts'

namespace :scrape do # rubocop:disable Metrics/BlockLength
  desc 'Scrape all data from all active broadcasts that have not been scraped in over 1 week.'
  task all_active_broadcasts: :environment do # rubocop:disable Metrics/BlockLength
    throttle_secs = ENV.fetch('THROTTLE_SECS', 0).to_i
    hourly_by_air_day = ENV.fetch('HOURLY_BY_AIR_DAY', 'false') == 'true'

    # TODO: air_time_start and air_time_end are not always being populated. Need to fix that before this will work
    active_broadcasts =
      if hourly_by_air_day
        current_time = Time.zone.now
        current_day_number = current_time.wday
        # check that the last scrape was greater than the broadcast.frequency_in_days range
        # that the broadcast is active
        # and that the broadcast finished within the past 90 minutes
        Broadcast.active
                 .where(air_day: current_day_number)
                 .where(
                   'air_time_end::time BETWEEN ? AND ?',
                   (current_time - 90.minutes).strftime('%H:%M:%S'),
                   current_time.strftime('%H:%M:%S')
                 )
      else
        Broadcast.active.where(last_scraped_at: ...1.week.ago)
      end

    error_count = 0
    message = <<~MSG
      Scraping broadcasts #{active_broadcasts.pluck(:id)} from task all_active_broadcasts,
        - throttle_secs: #{throttle_secs},
        - hourly_by_air_day: #{hourly_by_air_day}
    MSG
    ScrapeLogger.log message
    active_broadcasts.find_each do |broadcast|
      ScrapeBroadcasts.new.call(broadcast, throttle_secs:)
    rescue StandardError => e
      error_count += 1
      break if error_count > 5

      ScrapeLogger.log "Failed to scrape broadcast #{broadcast.id}: #{e.message}"
      sleep(3600) # Pause scraping speed for 1 hour
      next
    end
  end
end
