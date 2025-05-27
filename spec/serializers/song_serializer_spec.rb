# frozen_string_literal: true

require 'rails_helper'

describe SongSerializer do
  it 'serializes the expected attributes' do
    artist = create(:artist)
    song = create(:song, artist:)
    album = create(:album)
    playlist = create(:playlist)

    song.albums << album
    song.playlists << playlist

    serializer = described_class.new(song)
    serialized = serializer.as_json

    expect(serialized).to include(:id, :title, :duration)
    expect(serialized[:artist]).to be_present
    expect(serialized[:albums]).to be_an(Array)
    expect(serialized[:playlists]).to be_an(Array)
  end

  it 'includes associated artist' do
    artist = create(:artist)
    song = create(:song, artist:)

    serializer = described_class.new(song)
    serialized = serializer.as_json

    expect(serialized[:artist][:id]).to eq(artist.id)
  end

  it 'includes albums attribute' do
    artist = create(:artist)
    song = create(:song, artist:)
    album = create(:album, artist:)

    # Create the join entry
    create(:albums_song, album:, song:)

    # Make sure associations are loaded
    song.reload

    serializer = described_class.new(song)
    serialized = serializer.as_json

    # Just verify the albums key exists
    expect(serialized).to have_key(:albums)
    expect(serialized[:albums]).to be_an(Array)
  end

  it 'includes associated playlists' do
    artist = create(:artist)
    song = create(:song, artist:)
    playlist = create(:playlist)
    create(:playlists_song, playlist:, song:)

    serializer = described_class.new(song)
    serialized = serializer.as_json

    expect(serialized[:playlists].first[:id]).to eq(playlist.id)
  end
end
