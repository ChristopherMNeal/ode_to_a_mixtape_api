# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('lib/tasks/scrape_broadcast_titles.rb')

RSpec.describe ScrapeBroadcastTitles do
  describe '#call' do
    let(:station) do
      create(
        :station,
        name: 'XRAY.fm',
        base_url: 'https://xray.fm',
        broadcasts_index_url: 'https://xray.fm/shows/all'
      )
    end
    let(:html_content) { Rails.root.join('spec/fixtures/xray/broadcasts_index.html').read }

    before do
      stub_request(:get, station.broadcasts_index_url)
        .to_return(status: 200, body: html_content)
    end

    it 'creates or updates broadcasts with titles and URLs from the station index page' do
      expect { described_class.new.call(station) }
        .to change(Broadcast, :count).by(255)

      broadcast = Broadcast.find_by(title: 'Strange Babes')
      expect(broadcast.url).to eq('https://xray.fm/shows/strange-babes')
    end

    it 'does not create duplicate broadcasts' do
      described_class.new.call(station)

      expect { described_class.new.call(station) }
        .not_to(change(Broadcast, :count))
    end

    it 'parses the old broadcast title from the URL' do
      described_class.new.call(station)

      broadcast = Broadcast.find_by(title: 'PNKHSE Radio')
      expect(broadcast.old_title).to eq('Mutant Pop')
    end

    it 'updates the broadcast title if it has changed' do
      described_class.new.call(station)

      broadcast = Broadcast.find_by(title: 'PNKHSE Radio')
      expect(broadcast.old_title).to eq('Mutant Pop')

      html_content = Rails.root.join('spec/fixtures/xray/broadcasts_index.html').read
      html_content.gsub!('PNKHSE Radio', 'PUNKHOUSE Radio')
      stub_request(:get, station.broadcasts_index_url)
        .to_return(status: 200, body: html_content)

      expect { described_class.new.call(station) }
        .not_to(change(Broadcast, :count))

      broadcast.reload
      expect(broadcast)
        .to have_attributes(
          title: 'PUNKHOUSE Radio',
          old_title: 'PNKHSE Radio'
        )
    end
  end
end
