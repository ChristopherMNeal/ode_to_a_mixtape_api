# frozen_string_literal: true

# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

Station.find_or_create_by!(
  name: 'XRAY.fm',
  call_sign: 'KEXP',
  city: 'Portland',
  state: 'OR',
  base_url: 'https://xray.fm',
  broadcasts_index_url: 'https://xray.fm/shows/all',
  phone_number: '503-233-9729',
  text_number: '971-220-5979',
  email: 'dj@xray.fm',
  frequencies: {
    '107.1 FM': { call_sign: 'KXRY', city: 'Portland, OR' },
    '91.1 FM': { call_sign: 'KXRY', city: 'Portland, OR' },
    '91.7 FM': { call_sign: 'KXRY', city: 'Nehalem, OR' }
  }
)
# Station.find_or_create_by!(
#   name: 'KBOO',
#   call_sign: 'KBOO',
#   location: 'Portland, OR',
#   base_url: 'https://kboo.fm',
#   broadcasts_index_url: 'https://kboo.fm/program'
# )
# Station.find_or_create_by!(
#   name: 'KEXP',
#   call_sign: 'KEXP',
#   location: 'Seattle,WA',
#   base_url: 'https://kexp.org',
#   broadcasts_index_url: 'https://kexp.org/schedule'
# )

Broadcast.find_or_create_by!(
  station: Station.find_by(name: 'XRAY.fm'),
  title: 'Strange Babes',
  old_title: 'Strange Babes',
  url: 'https://xray.fm/shows/strange-babes'
)

# Station.all.each { |station| ScrapeBroadcastTitles.new.call(station) }
