# frozen_string_literal: true

# lib/tasks/scrape_broadcasts.rake
namespace :scrape do
  desc 'Scrape data and populate the database'
  task broadcasts: :environment do
    ScrapeBroadcasts.new.call
  end
end
