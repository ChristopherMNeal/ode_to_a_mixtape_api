# frozen_string_literal: true

require './lib/tasks/scrape_broadcasts'

# lib/tasks/scrape_broadcasts.rake
# Usage: rake scrape:broadcasts BROADCAST_ID=1
namespace :scrape do
  desc 'Scrape all data from a broadcast show page and populate the database with it.'
  task broadcasts: :environment do
    broadcast_id = ENV.fetch('BROADCAST_ID', nil)
    broadcast = Broadcast.find(broadcast_id)
    ScrapeBroadcasts.new.call(broadcast)
  end
end
