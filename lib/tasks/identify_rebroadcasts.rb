# frozen_string_literal: true

require 'i18n'

class IdentifyRebroadcasts # rubocop:disable Metrics/ClassLength
  KEYWORDS = %w[
    rerun
    rebroadcast
    re-broadcast
    copy
    replay
    reprise
    remix
    redux
    duplicate
    again
    evergreen
    (re)broadcast
  ].freeze

  def perform(broadcast)
    new.call(broadcast.id)
  end

  def call(broadcast_id)
    @cleaned_title_hash = cleaned_title_hash(broadcast_id)
    check_by_title_keywords(broadcast_id)
    check_by_parenthetical(broadcast_id)
    # check_by_identical_songs(broadcast_id) # This is much too slow to be worth it.
  end

  private

  def clean_title(string)
    I18n.transliterate(string.to_s.downcase.gsub(/[^a-z0-9]/, '').gsub(/#{KEYWORDS.join('|')}/i, '').strip)
  end

  def cleaned_title_hash(broadcast_id)
    Playlist.where(broadcast_id:, original_playlist_id: nil)
            .find_each(batch_size: 500)
            .each_with_object({}) do |playlist, hash|
      cleaned_title = clean_title(playlist.title)
      hash[cleaned_title] ||= []
      hash[cleaned_title] << playlist.id
    end
  end

  def print_titles
    max_title_length = @cleaned_title_hash.keys.map(&:length).max
    output = @cleaned_title_hash.map do |title, id_array|
      "  - #{title.ljust(max_title_length)}: #{id_array.join(', ')}"
    end
    puts 'All Cleaned Broadcast Titles:' # rubocop:disable Rails/Output
    puts output.sort # rubocop:disable Rails/Output
  end

  def check_by_title_keywords(broadcast_id) # rubocop:disable Metrics
    puts <<~MESSAGE # rubocop:disable Rails/Output
      ╔╦╗╔═╗╔╦╗╔═╗╦ ╦  ╔╗ ╦ ╦  ╔╦╗╦╔╦╗╦  ╔═╗
      ║║║╠═╣ ║ ║  ╠═╣  ╠╩╗╚╦╝   ║ ║ ║ ║  ║╣
      ╩ ╩╩ ╩ ╩ ╚═╝╩ ╩  ╚═╝ ╩    ╩ ╩ ╩ ╩═╝╚═╝
    MESSAGE
    print_titles
    keywords = KEYWORDS.map { |w| "%#{w}%" }
    playlists = Playlist.where(broadcast_id:)
                        .where(keywords.map { 'title ILIKE ?' }.join(' OR '), *keywords)
                        .where(original_playlist_id: nil).order(air_date: :asc)

    checked_playlist_ids = []
    playlists.each do |playlist|
      next if checked_playlist_ids.include?(playlist.id)

      cleaned_title = clean_title(playlist.title)
      possible_match_ids = @cleaned_title_hash[cleaned_title]
      checked_playlist_ids += possible_match_ids
      # Not all Broadcasts have Playlists with unique names... so this might not work.
      next if possible_match_ids.size > 12

      possible_matches = Playlist.where(id: possible_match_ids)
      prompt_for_match(possible_matches, 'title')
    end
  end

  def check_by_parenthetical(broadcast_id) # rubocop:disable Metrics
    # Checks for playlists that indicate a rebroadcast in the title
    # e.g. "Strange Strange Feelin' (rebroadcast)"
    # this uses calvin s font from https://patorjk.com/software/taag/#p=display&f=Calvin%20S&t=STRANGE%20BABES
    puts <<~MESSAGE # rubocop:disable Rails/Output
      ╔╦╗╔═╗╔╦╗╔═╗╦ ╦  ╔╗ ╦ ╦  ╔═╗╔═╗╦═╗╔═╗╔╗╔╔╦╗╦ ╦╔═╗╔╦╗╦╔═╗╔═╗╦
      ║║║╠═╣ ║ ║  ╠═╣  ╠╩╗╚╦╝  ╠═╝╠═╣╠╦╝║╣ ║║║ ║ ╠═╣║╣  ║ ║║  ╠═╣║
      ╩ ╩╩ ╩ ╩ ╚═╝╩ ╩  ╚═╝ ╩   ╩  ╩ ╩╩╚═╚═╝╝╚╝ ╩ ╩ ╩╚═╝ ╩ ╩╚═╝╩ ╩╩═╝
    MESSAGE
    checked_playlists = []

    opening_brackets = ['{', '[', '(', '|']
    pattern = /\s*[{\[(|].*$/
    Playlist.where(broadcast_id:)
            .where(opening_brackets.map { 'title ILIKE ?' }.join(' OR '), *opening_brackets.map { |b| "%#{b}%" })
            .where(original_playlist_id: nil)
            .order(air_date: :asc)
            .find_each do |playlist|
      next if playlist.rebroadcast? || checked_playlists.include?(playlist)

      # Use regex to get the part before any opening bracket
      original_title = playlist.title.sub(pattern, '').strip
      possible_matches =
        Playlist
        .where(broadcast_id:, original_playlist_id: nil)
        .where('title iLIKE ?', "#{original_title}%")
      checked_playlists += possible_matches

      prompt_for_match(possible_matches, 'parenthetical')
    end
  end

  def check_by_identical_songs(broadcast_id) # rubocop:disable Metrics
    puts <<~MESSAGE # rubocop:disable Rails/Output
      ╔╦╗╔═╗╔╦╗╔═╗╦ ╦  ╔╗ ╦ ╦  ╦╔╦╗╔═╗╔╗╔╔╦╗╦╔═╗╔═╗╦    ╔═╗╔═╗╔╗╔╔═╗╔═╗
      ║║║╠═╣ ║ ║  ╠═╣  ╠╩╗╚╦╝  ║ ║║║╣ ║║║ ║ ║║  ╠═╣║    ╚═╗║ ║║║║║ ╦╚═╗
      ╩ ╩╩ ╩ ╩ ╚═╝╩ ╩  ╚═╝ ╩   ╩═╩╝╚═╝╝╚╝ ╩ ╩╚═╝╩ ╩╩═╝  ╚═╝╚═╝╝╚╝╚═╝╚═╝
    MESSAGE
    # Preload songs for all playlists to avoid N+1 query issues
    playlists_with_songs = Playlist.joins(:songs).where(broadcast_id:)

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
    possible_matches.where.not(id: original_playlist.id).update_all(original_playlist_id: original_playlist.id) # rubocop:disable Rails/SkipsModelValidations
  end

  def prompt_for_match(possible_matches, type) # rubocop:disable Metrics
    return unless possible_matches.count > 1

    max_title_length = possible_matches.map(&:title).max_by(&:length).length
    matches_with_index = possible_matches.map.with_index do |match, index|
      num = (index + 1).to_s
      title = match.title
      date = match.air_date.strftime('%Y-%m-%d')
      song_ids = match.songs.pluck(:id).join(', ')
      "#{num.rjust(2)}: #{title.ljust(max_title_length)} (#{date}) songs: #{song_ids}"
    end
    puts <<~PROMPT # rubocop:disable Rails/Output
      Matching by #{type} there are #{possible_matches.count} possible matches.
      If all playlists are the same, ENTER THE NUMBER OF THE ORIGINAL PLAYLIST.
      All other playlists will be updated to reference the original playlist.
      OTHERWISE, enter 'n' to skip.
      #{matches_with_index.join("\n")}
    PROMPT
    response = $stdin.gets.chomp
    return unless response.to_i.positive?

    original_playlist = possible_matches[response.to_i - 1]
    update_rebroadcasts(original_playlist, possible_matches)
  end
end
