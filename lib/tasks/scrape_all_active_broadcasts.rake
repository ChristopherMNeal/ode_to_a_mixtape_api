# frozen_string_literal: true

require './lib/tasks/scrape_broadcasts'

namespace :scrape do # rubocop:disable Metrics/BlockLength
  desc 'Scrape all data from all active broadcasts that have not been scraped in over 1 week.'
  task all_active_broadcasts: :environment do # rubocop:disable Metrics/BlockLength
    throttle_secs = ENV.fetch('THROTTLE_SECS', 0).to_i
    hourly_by_air_day = ENV.fetch('HOURLY_BY_AIR_DAY', 'false') == 'true'
    scrape_inactive_broadcasts = ENV.fetch('SCRAPE_INACTIVE', 'false') == 'true'

    # TODO: air_time_start and air_time_end are not always being populated. Need to fix that before this will work
    scope = scrape_inactive_broadcasts ? Broadcast.where(active: false) : Broadcast.active
    broadcasts =
      if hourly_by_air_day
        current_time = Time.zone.now
        current_day_number = current_time.wday
        # check that the last scrape was greater than the broadcast.frequency_in_days range
        # and that the broadcast finished within the past 90 minutes
        scope.where(air_day: current_day_number)
             .where(
               'air_time_end::time BETWEEN ? AND ?',
               (current_time - 90.minutes).strftime('%H:%M:%S'),
               current_time.strftime('%H:%M:%S')
             )
      else
        scope.where(last_scraped_at: ...1.week.ago)
      end

    error_count = 0
    message = <<~MSG
      Scraping broadcasts #{broadcasts.pluck(:id)} from task all_active_broadcasts,
        - throttle_secs: #{throttle_secs},
        - hourly_by_air_day: #{hourly_by_air_day}
    MSG
    ScrapeLogger.log message
    broadcasts.find_each do |broadcast|
      ScrapeBroadcasts.new(broadcast, throttle_secs:).call
    rescue StandardError => e
      error_count += 1
      break if error_count > 5

      ScrapeLogger.log "Failed to scrape broadcast #{broadcast.id}: #{e.message}"
      ScrapeLogger.log e.backtrace&.join("\n")
      sleep(3600) # Pause scraping speed for 1 hour
      next
    end
  end
end
