# frozen_string_literal: true

require 'rails_helper'

describe ArtistSerializer do
  it 'serializes the expected attributes' do
    artist = create(:artist)
    create(:song, artist:)
    create(:album, artist:)

    serializer = described_class.new(artist)
    serialized = serializer.as_json

    expect(serialized).to include(:id, :name, :bio)
    expect(serialized[:songs]).to be_an(Array)
    expect(serialized[:albums]).to be_an(Array)
  end

  it 'includes associated songs' do
    artist = create(:artist)
    song = create(:song, artist:)

    serializer = described_class.new(artist)
    serialized = serializer.as_json

    expect(serialized[:songs].first[:id]).to eq(song.id)
  end

  it 'includes albums attribute' do
    artist = create(:artist)
    create(:album, artist:)

    # Ensure albums are loaded for serialization
    artist.reload

    serializer = described_class.new(artist)
    serialized = serializer.as_json

    # Just verify the albums key exists
    expect(serialized).to have_key(:albums)
    expect(serialized[:albums]).to be_an(Array)
  end
end
