# frozen_string_literal: true

class IdentifyRebroadcasts
  def perform(broadcast)
    new.call(broadcast)
  end

  def call(broadcast)
    playlists = broadcast.playlists.where(original_playlist_id: nil).order(air_date: :asc)
    check_by_parenthetical(playlists) # fast
    check_by_identical_songs(playlists) # slower
  end

  private

  def check_by_parenthetical(playlists)
    # Checks for playlists that indicate a rebroadcast in the title
    # e.g. "Strange Strange Feelin' (rebroadcast)"
    # this uses calvin s font from https://patorjk.com/software/taag/#p=display&f=Calvin%20S&t=STRANGE%20BABES
    puts <<~MESSAGE
      ┌┬┐┌─┐┌┬┐┌─┐┬ ┬  ┌┐ ┬ ┬  ┌─┐┌─┐┬─┐┌─┐┌┐┌┌┬┐┬ ┬┌─┐┌┬┐┬┌─┐┌─┐┬
      │││├─┤ │ │  ├─┤  ├┴┐└┬┘  ├─┘├─┤├┬┘├┤ │││ │ ├─┤├┤  │ ││  ├─┤│
      ┴ ┴┴ ┴ ┴ └─┘┴ ┴  └─┘ ┴   ┴  ┴ ┴┴└─└─┘┘└┘ ┴ ┴ ┴└─┘ ┴ ┴└─┘┴ ┴┴─┘
    MESSAGE
    checked_playlists = []
    playlists.where('title iLIKE ?', '%(%').find_each do |playlist|
      next if playlist.rebroadcast? || checked_playlists.include?(playlist)

      original_title = playlist.title.split('(').first.strip
      possible_matches = playlists.where('title iLIKE ?', "#{original_title}%")
      checked_playlists += possible_matches
      # make the change automatically if there's a clear match with the original title + (rebroadcast)
      rebroadcast_patterns = /\((re-?broadcast)|(copy)|(rerun)\)/i

      if possible_matches.map do |playlist|
        playlist.title.gsub(original_title, '').gsub(rebroadcast_patterns, '').strip.downcase
      end.uniq.sort == ['']
        update_rebroadcasts(possible_matches.first, possible_matches)
        next
      end

      prompt_for_match(possible_matches, 'parenthetical')
    end
  end

  def check_by_identical_songs(playlists)
    puts <<~MESSAGE
      ┌┬┐┌─┐┌┬┐┌─┐┬ ┬  ┌┐ ┬ ┬  ┬┌┬┐┌─┐┌┐┌┌┬┐┬┌─┐┌─┐┬    ┌─┐┌─┐┌┐┌┌─┐┌─┐
      │││├─┤ │ │  ├─┤  ├┴┐└┬┘  │ ││├┤ │││ │ ││  ├─┤│    └─┐│ │││││ ┬└─┐
      ┴ ┴┴ ┴ ┴ └─┘┴ ┴  └─┘ ┴   ┴─┴┘└─┘┘└┘ ┴ ┴└─┘┴ ┴┴─┘  └─┘└─┘┘└┘└─┘└─┘
    MESSAGE
    # Preload songs for all playlists to avoid N+1 query issues
    playlists_with_songs = Playlist.includes(:songs).find(playlists.ids)

    # Group playlists by their song IDs
    playlist_groups = playlists_with_songs.each_with_object(Hash.new { |h, k| h[k] = [] }) do |playlist, groups|
      next if playlist.rebroadcast? || playlist.songs.empty?

      song_ids = playlist.songs.ids.sort
      groups[song_ids] << playlist
    end

    playlist_groups.each_value do |possible_matches|
      next if possible_matches.size <= 1

      # convert to active record relation
      possible_matches = Playlist.where(id: possible_matches.map(&:id))
      prompt_for_match(possible_matches, 'identical songs')
    end
  end

  def update_rebroadcasts(original_playlist, possible_matches)
    possible_matches.where.not(id: original_playlist.id).update_all(original_playlist_id: original_playlist.id)
  end

  def prompt_for_match(possible_matches, type) # rubocop:disable Metrics/AbcSize
    return unless possible_matches.count > 1

    max_title_length = possible_matches.map(&:title).max_by(&:length).length
    matches_with_index = possible_matches.map.with_index do |match, index|
      num = (index + 1).to_s
      title = match.title
      date = match.air_date.strftime('%Y-%m-%d')
      song_ids = match.songs.pluck(:id).join(', ')
      "#{num.rjust(2)}: #{title.ljust(max_title_length)} (#{date}) songs: #{song_ids}"
    end
    prompt = <<~PROMPT
      Matching by #{type} there are #{possible_matches.count} possible matches.
      SQL Query: #{possible_matches.to_sql}
      If all playlists are the same, ENTER THE NUMBER OF THE ORIGINAL PLAYLIST.
      All other playlists will be updated to reference the original playlist.
      OTHERWISE, enter 'n' to skip.
      #{matches_with_index.join("\n")}
    PROMPT
    puts prompt
    response = $stdin.gets.chomp
    return unless response.to_i.positive?

    original_playlist = possible_matches[response.to_i - 1]
    update_rebroadcasts(original_playlist, possible_matches)
  end
end
