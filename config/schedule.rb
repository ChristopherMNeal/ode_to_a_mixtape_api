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

# THIS NEEDS TWEAKING
# It's creating cron jobs that include the environment, which isn't working. Also I'd like to adjust the times.

# # every hour scrape broadcasts that were expected to air a new episode in the last hour
# every :hour do
#   rake 'scrape:all_active_broadcasts THROTTLE_SECS=5 BY_AIR_DAY=true'
# end

# # catch any broadcasts that were missed by the hourly job
# every :day, at: '1:00 am' do
#   rake 'scrape:broadcast_titles STATION_ID=1'
#   rake 'scrape:all_active_broadcasts THROTTLE_SECS=5'
# end

# # scrape one unscraped broadcast every day at 4:00 am
# # May need to adjust throttle_secs
# # every :day, at: '4:00 am' do
# every :hour do
#   rake 'scrape:unscraped_broadcasts BROADCAST_COUNT=1 THROTTLE_SECS=5'
# end
