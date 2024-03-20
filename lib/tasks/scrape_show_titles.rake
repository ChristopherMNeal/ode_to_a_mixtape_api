# frozen_string_literal: true

# lib/tasks/scrape_titles.rake
namespace :scrape_titles do
  desc 'Check the website for new show titles and populate the database with them.'
  task populate: :environment do
    ScrapeTitles.new.call
  end
end
