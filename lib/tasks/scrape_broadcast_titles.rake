# frozen_string_literal: true

require './lib/tasks/scrape_broadcast_titles'

# lib/tasks/scrape_titles.rake
# Usage: rake scrape:broadcast_titles
namespace :scrape do
  desc 'Check the website for new broadcast titles and populate the database with them ' \
       'with minimal info from the broadcasts index.'
  task broadcast_titles: :environment do
    ScrapeBroadcastTitles.new.call(station = Station.find_by(name: 'XRAY.fm'))
  end
end
