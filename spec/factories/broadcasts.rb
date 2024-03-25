# frozen_string_literal: true

FactoryBot.define do
  factory :broadcast do
    station { FactoryBot.create(:station) }
    title { 'Strange Babes' }
    old_title { 'Strange Babes' }
    url { 'https://xray.fm/shows/strange-babes' }
  end
end
