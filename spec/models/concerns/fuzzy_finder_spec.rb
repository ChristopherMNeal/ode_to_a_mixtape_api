# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'FuzzyFinder' do
  let(:klass) { Artist }
  let(:column) { :name }
  let(:value) { 'booker t and the mgs' }
  let!(:artists) do
    [
      'booker t and the mgs',
      'Booker T & The MG',
      "Booke T & The MG's",
      'Booker T. and Priscilla',
      'Booker T',
      'Booker T &',
      'The C and C Boys',
      'Slaughter and the Dogs',
      'Tank and The Bangas',
      'Bob Dylan and the Band',
      'Kawaliwa and Mary w/ The AGS Boys',
      'Bo & The Weevils',
      'Philip Cohran And The',
      'The Fantastic Aleems',
      'prince charles and the crusaders'
    ].each do |name|
      FactoryBot.create(
        :artist,
        name:
      )
    end
  end

  describe 'find' do
    it 'returns the artist with the highest similarity' do
      expect(FuzzyFinder.fuzzy_find(klass, column, value).map(&:name)).to eq([artists.first])
    end
  end

  describe '#find_across_multiple_thresholds' do
    let(:record_count_warning_threshold) { 0 }
    let(:low_threshold) { 0.1 }
    let(:high_threshold) { 1.0 }
    let(:find_across_multiple_thresholds) do
      FuzzyFinder
        .find_across_multiple_thresholds(
          klass,
          column,
          value,
          low_threshold:,
          high_threshold:,
          record_count_warning_threshold:
        )
    end

    it 'returns the artist in order of similarity' do # rubocop:disable RSpec/ExampleLength
      expect(find_across_multiple_thresholds.transform_values { |artists| artists.pluck(:name) }).to eq(
        {
          1.0 => [],
          0.9 => ['booker t and the mgs'],
          0.8 => [],
          0.7 => [],
          0.6 => ['Booker T & The MG'],
          0.5 => [],
          0.4 => ["Booke T & The MG's",
                  'Booker T. and Priscilla',
                  'Booker T',
                  'Booker T &',
                  'The C and C Boys'],
          0.3 => ['Slaughter and the Dogs',
                  'Tank and The Bangas',
                  'Bob Dylan and the Band',
                  'Kawaliwa and Mary w/ The AGS Boys'],
          0.2 => ['Bo & The Weevils',
                  'Philip Cohran And The'],
          0.1 => ['The Fantastic Aleems',
                  'prince charles and the crusaders']
        }
      )
    end

    context 'when the record count exceeds the warning threshold' do
      let(:record_count_warning_threshold) { 4 }
      let(:low_threshold) { 0.2 }
      let(:high_threshold) { 0.5 }
      let(:expected_output) do
        <<~OUTPUT
          Threshold 0.4 has 5 records. The search may be too broad.
          Rerun search with 'record_count_warning_threshold: 0' to suppress this message.
        OUTPUT
      end

      it 'displays a warning message' do
        expect { find_across_multiple_thresholds }.to output(expected_output).to_stdout
      end

      it 'returns the artist in order of similarity with counts where the threshold is exceeded' do
        expect(find_across_multiple_thresholds.transform_values { |artists| artists.pluck(:name) }).to eq(
          { 0.5 => ['booker t and the mgs', 'Booker T & The MG'],
            0.4 => [], # empty because the warning threshold is exceeded
            0.3 => ['Slaughter and the Dogs',
                    'Tank and The Bangas',
                    'Bob Dylan and the Band',
                    'Kawaliwa and Mary w/ The AGS Boys'],
            0.2 => ['Bo & The Weevils',
                    'Philip Cohran And The'] }
        )
      end
    end
  end
end
