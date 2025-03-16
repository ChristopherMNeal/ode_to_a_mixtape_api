# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ScrapeLogger, type: :helper do
  let(:message) { 'Test message' }
  let(:timestamp) { '20220101' }
  let(:log_file) { "log/#{timestamp}_test_scrape.log" }

  before { allow(Time.zone).to receive(:now).and_return(Time.zone.parse('2022-01-01 00:00:00')) }

  describe '.log' do
    context 'when not in test environment' do
      it 'outputs the message to stdout' do
        allow(Rails.env).to receive(:test?).and_return(false)
        expect { described_class.log(message) }.to output("#{message}\n").to_stdout
      end
    end

    context 'when in test environment' do
      it 'does not output the message to stdout' do
        allow(Rails.env).to receive(:test?).and_return(true)
        expect { described_class.log(message) }.not_to output.to_stdout
      end
    end

    it 'appends the message to the log file' do
      expect(File).to receive(:open).with(log_file, 'a') # rubocop:disable RSpec/MessageSpies
      described_class.log(message)
    end

    it 'formats the message with the current time' do
      formatted_time = Time.zone.now.strftime('%Y-%m-%d %H:%M:%S')
      formatted_message = "#{formatted_time}: #{message}"

      file_double = instance_double(File)
      allow(File).to receive(:open).with(log_file, 'a').and_yield(file_double)
      expect(file_double).to receive(:puts).with(formatted_message) # rubocop:disable RSpec/MessageSpies

      described_class.log(message)
    end
  end
end
