# frozen_string_literal: true

FactoryBot.define do
  factory :genre do
    sequence(name) { |n| "Electric Disco Pop Opera #{n}" }
  end
end
