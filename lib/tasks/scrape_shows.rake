# frozen_string_literal: true

# lib/tasks/scrape.rake
namespace :scrape do
  desc 'Scrape data and populate the database'
  task populate: :environment do
    Scrape.new.call
  end
end
