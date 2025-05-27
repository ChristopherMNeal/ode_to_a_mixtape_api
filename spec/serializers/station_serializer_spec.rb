# frozen_string_literal: true

require 'rails_helper'

describe StationSerializer do
  it 'serializes the expected attributes' do
    station = create(:station)
    create_list(:broadcast, 2, station:)

    serializer = described_class.new(station)
    serialized = serializer.as_json

    expect(serialized).to include(:id, :name, :call_sign, :city, :state, :base_url, :frequencies)
    expect(serialized[:broadcasts]).to be_an(Array)
    expect(serialized[:broadcasts].length).to eq(2)
  end

  it 'includes associated broadcasts' do
    station = create(:station)
    broadcast = create(:broadcast, station:)

    serializer = described_class.new(station)
    serialized = serializer.as_json

    expect(serialized[:broadcasts].first[:id]).to eq(broadcast.id)
  end

  it 'handles frequencies as JSON' do
    frequencies = { 'FM' => '90.1', 'HD' => '90.1-1' }
    station = create(:station, frequencies:)

    serializer = described_class.new(station)
    serialized = serializer.as_json

    expect(serialized[:frequencies]).to eq(frequencies)
  end
end
