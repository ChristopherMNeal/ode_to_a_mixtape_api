# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('lib/tasks/scrapers/broadcast_index_scraper.rb')
require Rails.root.join('lib/tasks/scrapers/broadcast_metadata_extractor.rb')

RSpec.describe BroadcastMetadataExtractor do
  subject(:extractor) { described_class.new(broadcast) }

  let(:station) do
    create(
      :station,
      name: 'XRAY.fm',
      base_url:,
      broadcasts_index_url: "#{base_url}/shows/all"
    )
  end
  let(:broadcast) do
    create(
      :broadcast,
      station:,
      title: 'Strange Babes',
      old_title: 'Strange Babes',
      url: "#{base_url}/shows/#{broadcast_name}",
      air_day: nil,
      air_time_start: nil,
      air_time_end: nil,
      active: nil
    )
  end
  let(:base_url) { 'https://xray.fm' }
  let(:broadcast_name) { 'strange-babes' }
  let(:html_content) { Rails.root.join('spec/fixtures/xray/strange-babes-broadcast-index-1.html').read }
  let(:broadcast_index_doc) { Nokogiri::HTML(html_content) }

  before do
    # Stub logger to prevent test noise
    allow_any_instance_of(described_class).to receive(:scrape_logger)
  end

  describe '#update_broadcast_details' do
    before do
      # Stub BroadcastIndexScraper methods
      allow_any_instance_of(BroadcastIndexScraper).to receive(:fetch_broadcast_dates)
        .and_return([Date.new(2021, 4, 27), Date.new(2021, 4, 20), Date.new(2021, 4, 13)])

      # Skip DJ-related functionality by returning nil from scrape_dj_info
      allow(extractor).to receive(:scrape_dj_info).and_return(nil)

      # Stub methods called within update_broadcast_details
      allow(extractor).to receive(:add_broadcast_start_time)
    end

    it 'updates the broadcast frequency and active status' do
      # Override determine_active_status since actual implementation looks at playlists
      allow(extractor).to receive(:determine_active_status).and_return(true)

      extractor.update_broadcast_details(broadcast_index_doc)

      expect(broadcast.frequency_in_days).to eq(7) # Weekly show (7 days between episodes)
      expect(broadcast.active).to be true
    end

    it 'saves the broadcast if changes were made' do
      expect(broadcast).to receive(:save!)
      extractor.update_broadcast_details(broadcast_index_doc)
    end

    it 'calls scrape_dj_info with the index page' do
      expect(extractor).to receive(:scrape_dj_info).with(broadcast_index_doc).and_return(nil)
      extractor.update_broadcast_details(broadcast_index_doc)
    end
  end

  describe '#calculate_frequency_in_days' do
    context 'with regular broadcast schedule' do
      it 'calculates the frequency from consecutive dates' do
        dates = [Date.new(2021, 4, 27), Date.new(2021, 4, 20), Date.new(2021, 4, 13)]
        frequency = extractor.calculate_frequency_in_days(dates)
        expect(frequency).to eq(7) # Weekly show
      end
    end

    context 'with irregular broadcast schedule' do
      it 'uses the maximum gap between broadcasts' do
        dates = [Date.new(2021, 4, 27), Date.new(2021, 4, 20), Date.new(2021, 4, 6)] # 7 days, then 14 days
        frequency = extractor.calculate_frequency_in_days(dates)
        expect(frequency).to eq(14) # Biweekly max gap
      end
    end

    context 'with insufficient data' do
      it 'returns a default value for annual shows' do
        dates = [Date.new(2021, 4, 27), Date.new(2021, 4, 20)]
        frequency = extractor.calculate_frequency_in_days(dates)
        expect(frequency).to eq(123) # Default value
      end
    end
  end

  describe '#determine_active_status' do
    let(:today) { Time.zone.today }

    it 'marks a broadcast as active if recent episodes exist' do
      # Recent broadcast within 3x the frequency
      dates = [(today - 14.days), (today - 21.days), (today - 28.days)]
      frequency = 7 # Weekly show

      active = extractor.determine_active_status(dates, frequency)
      expect(active).to be true
    end

    it 'marks a broadcast as inactive if no recent episodes' do
      # Last broadcast was 4x the frequency ago (too old)
      dates = [(today - 28.days), (today - 35.days), (today - 42.days)]
      frequency = 7 # Weekly show

      active = extractor.determine_active_status(dates, frequency)
      expect(active).to be false
    end
  end

  describe '#add_broadcast_start_time' do
    context 'with air times information available' do
      let(:html_with_air_times) do
        '<div class="airtimes-container">
           <span class="weekday">Tuesday</span>
           <span class="airtime">4:00pm - 5:00pm</span>
         </div>'
      end
      let(:doc_with_air_times) { Nokogiri::HTML(html_with_air_times) }

      it 'extracts air day and times from the page' do
        # Need to use UTC times to match what we're getting in the tests
        start_time = Time.utc(2000, 1, 1, 16, 0, 0)
        end_time = Time.utc(2000, 1, 1, 17, 0, 0)
        allow(extractor).to receive(:parse_air_times).and_return([2, start_time, end_time])

        extractor.add_broadcast_start_time(doc_with_air_times)

        expect(broadcast.air_day).to eq(2) # Tuesday
        # Just check the hour and minute directly using matching
        expect(broadcast.air_day).to eq(2) # Tuesday
        expect(broadcast.air_time_start.hour).to eq(16)
        expect(broadcast.air_time_start.min).to eq(0)

        expect(broadcast.air_time_end.hour).to eq(17)
        expect(broadcast.air_time_end.min).to eq(0)
      end
    end

    context 'without air times information' do
      let(:html_without_air_times) { '<div class="some-other-content"></div>' }
      let(:doc_without_air_times) { Nokogiri::HTML(html_without_air_times) }

      it 'attempts to get air time from the most recent broadcast' do
        allow(extractor).to receive(:most_recent_broadcast_air_time)
          .and_return([2, Time.utc(2000, 1, 1, 16, 0, 0), nil])

        extractor.add_broadcast_start_time(doc_without_air_times)

        expect(broadcast.air_day).to eq(2) # Tuesday
        expect(broadcast.air_time_start.hour).to eq(16)
        expect(broadcast.air_time_start.min).to eq(0)
        expect(broadcast.air_time_end).to be_nil
      end
    end

    context 'with invalid air times' do
      it 'logs an error when air times cannot be determined' do
        allow(extractor).to receive_messages(parse_air_times: [nil, nil, nil],
                                             most_recent_broadcast_air_time: [
                                               nil, nil, nil
                                             ])

        expect(extractor).to receive(:scrape_logger).with(/Unable to determine air times/)
        extractor.add_broadcast_start_time(broadcast_index_doc)
      end
    end
  end

  # The scrape_dj_info method appears to be private in the implementation,
  # so we shouldn't test it directly. We can test it through the update_broadcast_details
  # method which calls it internally.
end
