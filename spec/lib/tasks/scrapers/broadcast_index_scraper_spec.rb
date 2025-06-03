# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'
require Rails.root.join('lib/tasks/scrapers/broadcast_index_scraper.rb')

RSpec.describe BroadcastIndexScraper do
  subject(:scraper) { described_class.new(broadcast, throttle_secs) }

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
      url: "#{base_url}/shows/#{broadcast_name}"
    )
  end
  let(:base_url) { 'https://xray.fm' }
  let(:broadcast_name) { 'strange-babes' }
  let(:throttle_secs) { 0 }

  let(:html_content_1) { Rails.root.join('spec/fixtures/xray/strange-babes-broadcast-index-1.html').read }
  let(:html_content_2) { Rails.root.join('spec/fixtures/xray/strange-babes-broadcast-index-2.html').read }
  let(:index_url_page_1) { "#{base_url}/programs/#{broadcast_name}/page:1?url=broadcasts%2F#{broadcast_name}" }
  let(:index_url_page_2) { "#{base_url}/programs/#{broadcast_name}/page:2?url=broadcasts%2F#{broadcast_name}" }

  before do
    # Stub logger to prevent test noise
    allow_any_instance_of(described_class).to receive(:scrape_logger)
  end

  describe '#open_broadcasts_index_page' do
    before do
      stub_request(:get, index_url_page_1).to_return(status: 200, body: html_content_1)
    end

    it 'fetches the broadcast index page for a given page number' do
      result = scraper.open_broadcasts_index_page(broadcast_name, 1)
      expect(result).to be_a(Nokogiri::HTML::Document)
      expect(result.css('title').text).to include('Strange Babes')
    end

    context 'when HTTP error occurs' do
      before do
        stub_request(:get, index_url_page_2).to_return(status: 404)
      end

      it 'returns nil and logs the error' do
        expect(scraper).to receive(:scrape_logger).with(/Error opening page/)
        expect(scraper.open_broadcasts_index_page(broadcast_name, 2)).to be_nil
      end
    end

    context 'when throttling is configured' do
      let(:throttle_secs) { 0.1 }

      it 'delays the request according to the throttle setting' do
        expect(scraper).to receive(:sleep).with(throttle_secs)
        scraper.open_broadcasts_index_page(broadcast_name, 1)
      end
    end

    context 'when page is cached' do
      it 'uses cached page on subsequent calls' do
        # First call should make an HTTP request
        first_result = scraper.open_broadcasts_index_page(broadcast_name, 1)

        # Second call should use cached result
        expect(URI).not_to receive(:open)
        second_result = scraper.open_broadcasts_index_page(broadcast_name, 1)

        expect(first_result).to eq(second_result)
      end
    end
  end

  describe '#find_start_date_page_number' do
    let(:start_date) { Date.new(2021, 3, 1) }

    before do
      stub_request(:get, index_url_page_1).to_return(status: 200, body: html_content_1)
      stub_request(:get, index_url_page_2).to_return(status: 200, body: html_content_2)

      # Add stubs for page 3 and 4 to avoid real HTTP connections
      stub_request(:get, "#{base_url}/programs/#{broadcast_name}/page:3?url=broadcasts%2F#{broadcast_name}")
        .to_return(status: 200, body: html_content_2)
      stub_request(:get, "#{base_url}/programs/#{broadcast_name}/page:4?url=broadcasts%2F#{broadcast_name}")
        .to_return(status: 200, body: '')

      # Allow the method to fetch broadcast dates
      allow(scraper).to receive(:fetch_broadcast_dates).with(kind_of(Nokogiri::HTML::Document))
                                                       .and_return(
                                                         [Date.new(2021, 4, 27), Date.new(2021, 4, 20),
                                                          Date.new(2021, 4, 13)],
                                                         [Date.new(2021, 3, 30), Date.new(2021, 3, 23),
                                                          Date.new(2021, 3, 16), Date.new(2021, 3, 9)],
                                                         [Date.new(2021, 2, 23), Date.new(2021, 2, 16),
                                                          Date.new(2021, 2, 9)],
                                                         []
                                                       )

      # Mock the next_page_available? method to control pagination
      allow(scraper).to receive(:next_page_available?).and_return(true, true, false)
    end

    it 'finds the page number containing the broadcast closest to the start date' do
      page_number = scraper.find_start_date_page_number(broadcast_name, start_date)
      expect(page_number).to eq(3)
    end

    context 'when start date is on a later page' do
      let(:start_date) { Date.new(2021, 4, 15) }

      it 'returns the correct page number' do
        page_number = scraper.find_start_date_page_number(broadcast_name, start_date)
        expect(page_number).to eq(1)
      end
    end

    context 'when page fails to load' do
      before do
        stub_request(:get, index_url_page_1).to_return(status: 500)
      end

      it 'logs the error and returns page 1' do
        expect(scraper).to receive(:scrape_logger).with(/Error opening page/)

        # The method will also try to log that it failed to load the page
        allow(scraper).to receive(:scrape_logger).with(/Failed to load paginated broadcast index/)

        # Based on the implementation, if a page fails to load, the method breaks out of the loop
        # and returns the current page_number (which starts at 1)
        expect(scraper.find_start_date_page_number(broadcast_name, start_date)).to eq(1)
      end
    end
  end

  describe '#fetch_broadcast_dates' do
    before do
      stub_request(:get, index_url_page_1).to_return(status: 200, body: html_content_1)
    end

    it 'extracts broadcast dates from the page' do
      page = scraper.open_broadcasts_index_page(broadcast_name, 1)
      dates = scraper.fetch_broadcast_dates(page)

      expect(dates).to be_an(Array)
      expect(dates).not_to be_empty
      expect(dates.all? { |date| date.is_a?(Date) }).to be true
    end
  end
end
