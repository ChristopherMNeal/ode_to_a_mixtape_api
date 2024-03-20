# frozen_string_literal: true

require './lib/tasks/scrape_broadcasts'

# lib/tasks/scrape_broadcasts.rake
namespace :scrape do
  desc 'Scrape all data from a broadcast show page and populate the database with it.' \
       'Usage: rake scrape:broadcasts call on each broadcast.'
  task broadcasts: :environment do
    ScrapeBroadcasts.new.call(broadcast = Broadcast.find_by(title: 'Strange Babes'))
  end
end
