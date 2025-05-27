# frozen_string_literal: true

require 'rails_helper'

describe BroadcastSerializer do
  it 'serializes the expected attributes' do
    broadcast = create(:broadcast)
    serializer = described_class.new(broadcast)
    serialized = serializer.as_json

    expect(serialized).to include(:id, :title, :url, :air_day, :air_time_start, :air_time_end, :active)
    expect(serialized[:station]).to be_present
    expect(serialized[:dj]).to be_present
    expect(serialized[:playlists]).to be_an(Array)
  end
end
