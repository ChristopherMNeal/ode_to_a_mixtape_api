# frozen_string_literal: true

require './lib/tasks/scrape_broadcast_titles'

# Usage: rake scrape:broadcast_titles STATION_ID=1
namespace :scrape do
  desc 'Check the website for new broadcast titles and populate the database with them ' \
       'with minimal info from the broadcasts index.'
  task broadcast_titles: :environment do
    station_id = ENV.fetch('STATION_ID', nil)
    station = Station.find(station_id)
    ScrapeBroadcastTitles.new.call(station)
  end
end
