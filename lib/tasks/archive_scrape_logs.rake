# frozen_string_literal: true

require 'zlib'
require 'fileutils'

namespace :log do
  desc 'Archive and compress scrape logs'
  task archive_scrape_logs: :environment do
    log_dir = Rails.root.join('log')
    archive_dir = Rails.root.join('log/archives')
    FileUtils.mkdir_p(archive_dir)

    log_file_pattern = "#{Time.zone.now.strftime('%Y%m%d')}_scrape.log"

    Dir.glob(log_dir.join(log_file_pattern)).each do |file_path|
      output_file = "#{archive_dir}/#{File.basename(file_path)}.gz"

      Zlib::GzipWriter.open(output_file) do |gz|
        gz.write File.read(file_path)
      end

      puts "Archived and compressed: #{File.basename(file_path)}"

      FileUtils.rm(file_path)
    end
  end
end
