# frozen_string_literal: true

FactoryBot.define do
  factory :broadcast do
    station
    dj
    title { 'Strange Babes' }
    old_title { 'Strange Babes' }
    active { true }
    sequence(:url) { |n| "https://xray.fm/shows/strange-babes-#{n}" }
  end
end
