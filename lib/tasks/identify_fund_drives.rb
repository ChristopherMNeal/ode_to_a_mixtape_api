# frozen_string_literal: true

class IdentifyFundDrives
  KEYWORDS = ['%fund drive%', '%pledge drive%', '%fun drive%'].freeze
  def perform(station)
    new.call(station)
  end

  def call(station)
    broadcast_ids = station.broadcasts.pluck(:id)
    check_by_title(broadcast_ids) # fast
    # Implement logic to identify fund drive date span?
    # check_by_fund_drive_span(broadcast_ids)
  end

  private

  def check_by_title(broadcast_ids = nil)
    # Checks for playlists that indicate 'fund drive' in the title
    # e.g. "swag fills in, fall fund drive, records are played"
    scope = broadcast_ids.nil? ? Playlist.all : Playlist.where(broadcast_id: broadcast_ids)
    scope.where(KEYWORDS.map { 'title ILIKE ?' }.join(' OR '), *KEYWORDS)
         .find_each { |playlist| playlist.update(fund_drive: true) }
  end
end
