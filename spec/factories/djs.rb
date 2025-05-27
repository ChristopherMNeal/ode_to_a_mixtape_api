# frozen_string_literal: true

FactoryBot.define do
  factory :dj do
    dj_name { 'Strange Babes' }
    member_names { 'Jen O, KM Fizzy, and Magic Beans' }
    bio do
      <<~BIO
        Strange Babes is a long time Portland DJ crew consisting of members DJ Jen O, KM Fizzy and Magic Beans established in 2010.
        They bring a wide and formidable mix of underground gems across genres to XRAY.FM every Tuesday from 4-6pm and are proud to be one of the station's founding on air programs.
        Catch them out in clubs all over Portland including their monthly Danze Nite at Dynasty every 3rd Friday sponsored by XRAY.FM
        Strange Babes are hired to DJ public and private parties and events year round. For booking inquiries please write: strangebabesbooking@gmail.com
      BIO
    end
    email { 'strangebabesbooking@gmail.com' }
    twitter { 'strangebabes' }
    instagram { 'strangebabes' }
    facebook { 'strangebabes' }

    after(:create) do |dj|
      station = create(:station)
      dj.stations << station
      dj.djs_stations.find_by(station:)&.update(profile_url: 'https://xray.fm/profiles/strangebabes')
    end
  end
end
