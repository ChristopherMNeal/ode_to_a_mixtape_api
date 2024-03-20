# frozen_string_literal: true

# lib/tasks/scrape_shows.rake
namespace :scrape_shows do
  desc 'Scrape data and populate the database'
  task populate: :environment do
    ScrapeShows.new.call
  end
end
