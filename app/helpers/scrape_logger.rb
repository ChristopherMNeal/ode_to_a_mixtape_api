# frozen_string_literal: true

class ScrapeLogger
  def self.log(message)
    env = Rails.env
    Rails.logger.debug message unless env.test?

    timestamp = Time.zone.now.strftime('%Y%m%d')
    File.open("log/#{timestamp}_#{env}_scrape.log", 'a') do |f|
      time = Time.zone.now.strftime('%Y-%m-%d %H:%M:%S')
      f.puts "#{time}: #{message}"
    end
  end
end
