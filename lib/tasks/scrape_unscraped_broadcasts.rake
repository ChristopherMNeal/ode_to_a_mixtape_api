# frozen_string_literal: true

require './lib/tasks/scrape_broadcasts'

namespace :scrape do
  desc 'Scrape a specified number of previously unscraped broadcasts.'
  task unscraped_broadcasts: :environment do
    # load broadcasts in case one was added?
    # be rake scrape:broadcast_titles STATION_ID=1

    throttle_secs = ENV.fetch('THROTTLE_SECS', 0).to_i
    broadcast_count = ENV.fetch('BROADCAST_COUNT', 1)
    # Temporary addition of priority list for Xray.fm
    priority_list = Broadcast.active.where(
      last_scraped_at: nil,
      id: [58, 70, 86, 87, 90, 91, 93, 94, 95, 96, 118, 128, 132, 136, 137, 142, 148, 160, 169, 172, 177, 185, 202, 218,
           220, 226, 232, 251]
    )
    unscraped_broadcasts = priority_list.empty? ? Broadcast.active.where(last_scraped_at: nil) : priority_list
    if broadcast_count == 'all' || broadcast_count.to_i > unscraped_broadcasts.count
      broadcast_count = unscraped_broadcasts.count
    end

    ScrapeLogger.log <<~MSG
      Scraping #{broadcast_count} unscraped broadcasts from task unscraped_broadcast
        - throttle_secs: #{throttle_secs}
    MSG
    unscraped_broadcasts.limit(broadcast_count).order(:created_at).each do |broadcast|
      ScrapeBroadcasts.new.call(broadcast, throttle_secs:)
    end
  end
end
