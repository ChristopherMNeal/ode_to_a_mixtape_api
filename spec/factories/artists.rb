# frozen_string_literal: true

FactoryBot.define do
  factory :artist do
    sequence(:name) { |n| "Throbbing Gristle #{n}" }
    bio do
      bio = <<~BIO
        Throbbing Gristle were an English music and visual arts group formed in Kingston upon Hull by Genesis P-Orridge
        and Cosey Fanni Tutti, later joined by Peter "Sleazy" Christopherson and Chris Carter. They are widely regarded
        as pioneers of industrial music. Evolving from the experimental performance art group COUM Transmissions,
        Throbbing Gristle made their public debut in October 1976 in the COUM exhibition Prostitution, and released
        their debut single "United/Zyklon B Zombie" and debut album The Second Annual Report the following year.
        P-Orridge's lyrics mainly revolved around mysticism, extremist political ideologies, sexuality, dark or
        underground aspects of society, and idiosyncratic manipulation of language inspired by the techniques of
        William S. Burroughs.
      BIO
      bio.split("\n").map(&:strip).join(' ')
    end
  end
end
