# frozen_string_literal: true

require './lib/tasks/identify_rebroadcasts'

# Usage: rake task:identify_rebroadcasts
namespace :task do
  desc 'Find which playlists are rebroadcasts from previous shows and update the database with this information.'
  task identify_rebroadcasts: :environment do
    IdentifyRebroadcasts.new.call(broadcast = Broadcast.find_by(title: 'Strange Babes'))
  end
end
