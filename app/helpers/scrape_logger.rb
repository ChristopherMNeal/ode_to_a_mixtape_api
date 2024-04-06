# frozen_string_literal: true

class ScrapeLogger
  def self.log(message)
    puts message
    File.open('log/migration.log', 'a') do |f|
      time = Time.now.strftime('%Y-%m-%d %H:%M:%S')
      f.puts "#{time}: #{message}"
    end
  end
end
