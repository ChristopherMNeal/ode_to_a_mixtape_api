# frozen_string_literal: true

require 'rails_helper'

describe PlaylistSerializer do
  it 'serializes the expected attributes' do
    playlist = create(:playlist)
    song = create(:song)
    playlist.songs << song

    serializer = described_class.new(playlist)
    serialized = serializer.as_json

    expect(serialized).to include(:id, :title, :air_date, :playlist_url, :theme, :holiday, :fund_drive)
    expect(serialized[:broadcast]).to be_present if playlist.broadcast.present?
    expect(serialized[:station]).to be_present
    expect(serialized[:songs]).to be_an(Array)
  end

  it 'includes associated songs' do
    playlist = create(:playlist)
    song = create(:song)
    playlist.songs << song

    serializer = described_class.new(playlist)
    serialized = serializer.as_json

    expect(serialized[:songs].first[:id]).to eq(song.id)
  end

  it 'includes associated broadcast and station' do
    station = create(:station)
    broadcast = create(:broadcast, station:)
    playlist = create(:playlist, broadcast:, station:)

    serializer = described_class.new(playlist)
    serialized = serializer.as_json

    expect(serialized[:broadcast][:id]).to eq(broadcast.id)
    expect(serialized[:station][:id]).to eq(station.id)
  end
end
