# frozen_string_literal: true

FactoryBot.define do
  factory :dj do
    dj_name { 'MyString' }
    member_names { 'MyString' }
    profile_url { 'MyString' }
    bio { 'MyText' }
    email { 'MyString' }
    twitter { 'MyString' }
    instagram { 'MyString' }
    facebook { 'MyString' }
  end
end
