# frozen_string_literal: true

FactoryBot.define do
  factory :broadcast do
    station
    title { 'Strange Babes' }
    old_title { 'Strange Babes' }
    sequence(:url) { |n| "https://xray.fm/shows/strange-babes-#{n}" }
  end
end
