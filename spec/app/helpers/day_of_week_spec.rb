# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DayOfWeek, type: :helper do
  let(:day_of_week) { described_class }

  describe '#day_of_week_from_integer' do
    it 'returns the correct day of the week for a given integer' do
      expect(day_of_week.day_of_week_from_integer(1)).to eq('Monday')
    end

    it 'returns nil for an out of range integer' do
      expect(day_of_week.day_of_week_from_integer(7)).to be_nil
    end
  end

  describe '#integer_from_day_of_week' do
    it 'returns the correct integer for a given day of the week' do
      expect(day_of_week.integer_from_day_of_week('Tuesday')).to eq(2)
    end

    it 'returns nil for an invalid day of the week' do
      expect(day_of_week.integer_from_day_of_week('Funday')).to be_nil
    end

    it 'returns nil for a nil input' do
      expect(day_of_week.integer_from_day_of_week(nil)).to be_nil
    end

    it 'is case insensitive' do
      expect(day_of_week.integer_from_day_of_week('tuesday')).to eq(2)
    end

    it 'singularizes the day of the week' do
      expect(day_of_week.integer_from_day_of_week('Mondays')).to eq(1)
    end
  end
end
