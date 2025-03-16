# frozen_string_literal: true

# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

# Improve this:
# - It is creating cron jobs that include the environment, which isn't working
# - It's just not working; I'm not sure why. The tasks work and cron starts them, but nothing happens.

set :output, Rails.root.join('log/cron.log')

# every hour scrape broadcasts that were expected to air a new episode in the last hour
every :day, at: '12:00 am' do
  rake 'scrape:all_active_broadcasts THROTTLE_SECS=5 BY_AIR_DAY=true'
end

# catch any broadcasts that were missed by the hourly job
every :day, at: '1:00 am' do
  rake 'scrape:broadcast_titles STATION_ID=1'
  rake 'scrape:all_active_broadcasts THROTTLE_SECS=5'
end

# every :day, at: '4:00 am' do
every :hour do
  rake 'scrape:unscraped_broadcasts BROADCAST_COUNT=1 THROTTLE_SECS=5'
end

# rubocop:disable Metrics/LineLength
# crontab with logging
# */5 * * * * echo "cron is active at $(date)" >> /Users/christopherneal/cron_log.txt
# 0 * * * * /bin/bash -l -c 'cd /Users/christopherneal/Desktop/projects/ode_to_a_mixtape_api && echo "scrape hourly broadcasts cron job started at $(date)" >> /Users/christopherneal/cron_log.txt && bundle exec rake scrape:all_active_broadcasts THROTTLE_SECS=5 BY_AIR_DAY=true --silent && echo "scrape hourly broadcasts cron job completed at $(date)" >> /Users/christopherneal/cron_log.txt'
# 0 * * * * /bin/bash -l -c 'cd /Users/christopherneal/Desktop/projects/ode_to_a_mixtape_api && echo "scrape 1 unscraped broadcast cron job started at $(date)" >> /Users/christopherneal/cron_log.txt && bundle exec rake scrape:unscraped_broadcasts BROADCAST_COUNT=1 THROTTLE_SECS=5 --silent && echo "scrape 1 unscraped broadcast cron job completed at $(date)" >> /Users/christopherneal/cron_log.txt'
# 0 1 * * * /bin/bash -l -c 'cd /Users/christopherneal/Desktop/projects/ode_to_a_mixtape_api && echo "scrape broadcast titles cron job started at $(date)" >> /Users/christopherneal/cron_log.txt && bundle exec rake scrape:broadcast_titles STATION_ID=1 --silent && echo "scrape broadcast titles cron job completed at $(date)" >> /Users/christopherneal/cron_log.txt'
# 0 1 * * * /bin/bash -l -c 'cd /Users/christopherneal/Desktop/projects/ode_to_a_mixtape_api && echo "scrape all active broadcasts cron job started at $(date)" >> /Users/christopherneal/cron_log.txt && bundle exec rake scrape:all_active_broadcasts THROTTLE_SECS=5 --silent && echo "scrape all active broadcasts cron job completed at $(date)" >> /Users/christopherneal/cron_log.txt'
# rubocop:enable Metrics/LineLength
