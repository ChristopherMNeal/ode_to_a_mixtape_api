# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('lib/tasks/merge_duplicate_records')

RSpec.describe MergeDuplicateRecords do
  let(:klass) { Artist }
  let(:normalizable_hash) do
    { normalizable_column: 'name',
      merge_records: true }
  end
  let(:column_name) { 'name' }
  let(:normalized_column_name) { 'normalized_name' }
  let(:service) { described_class.new(klass, normalizable_hash) }
  let!(:name_list) do
    [
      'Sly And The Family Stone',
      'Sly and the Family Stone',
      'Sly & The Family Stone',
      'sly and the family stone',
      'Sly and the family stone'
    ]
  end

  let!(:similar_artists) do # rubocop:disable RSpec/LetSetup
    [
      'Sly And The Family Stone',
      'Sly and the Family Stone',
      'Sly & The Family Stone',
      'sly and the family stone',
      'Sly and the family stone'
    ].map do |name|
      artist = create(:artist)
      album1 = create(:album, artist:)
      album2 = create(:album, artist:)
      create(:song, artist:, albums: [album1])
      create(:song, artist:, albums: [album2])

      # Hack to update the name without triggering the normalizer
      artist.update_column(:name, name) # rubocop:disable Rails/SkipsModelValidations
      artist
    end
  end

  let!(:unique_artist) { create(:artist, name: 'prince') }

  let(:best_name) { NameFormatter.format_name(name_list) }

  before do
    unless klass.column_names.include?(column_name) && klass.column_names.include?(normalized_column_name)
      skip "Skipping because columns don't exist on #{klass}"
    end
  end

  context 'with child associations' do
    let(:duplicate_name) { name_list.excluding(best_name).first }
    let(:unique_name) { unique_artist.name }

    it 'merges duplicates and reassigns child records to the surviving parent' do
      artist1 = Artist.find_by(name: best_name)
      artist2 = Artist.find_by(name: duplicate_name)
      album1 = create(:album, artist: artist1)
      album2 = create(:album, artist: artist2)
      song1 = create(:song, artist: artist1)
      song2 = create(:song, artist: artist2)

      expect { service.perform }.to change(Artist, :count).by(-4)
      # Exactly one of the duplicates remains:
      surviving_artist = Artist.find_by(name: [best_name, duplicate_name])
      expect(surviving_artist).not_to be_nil

      # Check that the child records all belong to the same (surviving) artist
      [album1, album2, song1, song2].each do |child|
        expect(child.reload.artist_id).to eq(surviving_artist.id)
      end

      # The unique artist should be untouched
      expect(Artist.find_by(name: unique_name)).not_to be_nil
    end
  end

  describe '#perform' do
    context 'when columns do not exist' do
      let(:normalizable_hash) do
        { normalizable_column: 'nonexistent_column',
          merge_records: true }
      end

      it 'raises an error' do
        bad_service = described_class.new(klass, normalizable_hash)
        expect { bad_service.perform }.to raise_error(
          /does not have the necessary columns:/
        )
      end
    end

    context 'when columns exist' do
      it 'merges duplicates and leaves only one record per normalized name' do
        expect { service.perform }
          .to change(Artist, :count).by(-(name_list.size - 1))
      end

      it 'retains the best name (chosen by NameFormatter)' do
        service.perform
        merged_record = Artist.find_by(name: best_name)
        expect(merged_record).not_to be_nil
        expect(Artist.where(name: best_name).count).to eq(1)
      end

      it 'updates the primary record’s normalized_name' do
        service.perform
        expect(Artist.find_by(name: best_name)).to have_attributes(
          normalized_name: Normalizable.normalize_text(best_name),
          name: best_name
        )
      end

      it 'destroys the old duplicate records' do
        service.perform
        name_list.each do |old_name|
          next if old_name == best_name

          expect(Artist.find_by(name: old_name)).to be_nil
        end
      end
    end
  end

  describe '#choose_primary_record' do
    it 'selects a record that has the "best" name' do
      records = Artist.where(name: name_list)
      chosen = service.choose_primary_record(records)
      expect(chosen.name).to eq(best_name)
    end
  end
end
