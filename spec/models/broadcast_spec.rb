# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Broadcast do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:url) }
    it { is_expected.to validate_presence_of(:station_id) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:station) }
    it { is_expected.to have_many(:playlists) }
  end

  describe 'scopes' do
    let(:station) { FactoryBot.create(:station) }
    let(:broadcast) { FactoryBot.create(:broadcast, station:) }

    describe '.by_station' do
      it 'returns the broadcasts for a given station' do
        expect(described_class.by_station(station)).to eq([broadcast])
      end
    end

    describe '.active' do
      it 'returns the active broadcasts' do
        broadcast.update(active: true)
        expect(described_class.active).to eq([broadcast])
      end

      it 'does not return inactive broadcasts' do
        broadcast.update(active: false)
        expect(described_class.active).to eq([])
      end
    end
  end

  describe '#update_broadcast_title(title, url)' do
    context 'when the broadcast is a new record' do
      let(:broadcast) { build(:broadcast) }

      it 'creates an old_name attribute from the url' do
        broadcast.update_broadcast_title('title', 'http://example.com/old-title')
        expect(broadcast.old_title).to eq('Old Title')
      end
    end

    context 'when the broadcast is not a new record' do
      let(:broadcast) { FactoryBot.create(:broadcast, title: 'Old Title') }

      it 'updates the old_title attribute' do
        broadcast.update_broadcast_title('New Title', 'http://example.com/new-title')
        expect(broadcast.old_title).to eq('Old Title')
      end
    end
  end

  describe '#foreign_id' do
    let(:broadcast) { FactoryBot.create(:broadcast, url: 'http://example.com/playlist-id') }

    it 'returns the id of the playlist on the station website' do
      expect(broadcast.foreign_id).to eq('playlist-id')
    end
  end

  describe '#first_playlist' do
    let!(:broadcast) { FactoryBot.create(:broadcast) }
    let!(:playlists) { create_list(:playlist, 3, broadcast:) }

    it 'returns the first playlist by air_date' do
      expect(broadcast.first_playlist).to eq(playlists.last)
    end
  end

  describe '#last_playlist' do
    let!(:broadcast) { FactoryBot.create(:broadcast) }
    let!(:playlists) { create_list(:playlist, 3, broadcast:) }

    it 'returns the last playlist by air_date' do
      expect(broadcast.last_playlist).to eq(playlists.first)
    end
  end
end
