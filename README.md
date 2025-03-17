```
          __              __                                                        __                               
         /\ \            /\ \__                                      __            /\ \__                            
  ___    \_\ \     __    \ \ ,_\   ___          __          ___ ___ /\_\   __  _   \ \ ,_\    __     _____      __   
 / __`\  /'_` \  /'__`\   \ \ \/  / __`\      /'__`\      /' __` __`\/\ \ /\ \/'\   \ \ \/  /'__`\  /\ '__`\  /'__`\ 
/\ \L\ \/\ \L\ \/\  __/    \ \ \_/\ \L\ \    /\ \L\.\_    /\ \/\ \/\ \ \ \\/>  </    \ \ \_/\ \L\.\_\ \ \L\ \/\  __/ 
\ \____/\ \___,_\ \____\    \ \__\ \____/    \ \__/.\_\   \ \_\ \_\ \_\ \_\/\_/\_\    \ \__\ \__/.\_\\ \ ,__/\ \____\
 \/___/  \/__,_ /\/____/     \/__/\/___/      \/__/\/_/    \/_/\/_/\/_/\/_/\//\/_/     \/__/\/__/\/_/ \ \ \/  \/____/
                                                                                                       \ \_\         
                                                                                                        \/_/         
    ____________________________
  /|............................|
 | |:     ,-.   _____   ,-.    :|
 | |:    ( `)) [_____] ( `))   :|
 |v|:     `-`   ' ' '   `-`    :|
 |||:    ,________________.    :|
 |^|..../:::O::::::::::O:::\....|
 |/`---/--------------------`---|
 `.___/ /====/ /=//=/ /====/____/
```
# README
## Description
This is a project to scrape playlists from radio stations and store them in a database.
The goal is to have a database of playlists that can be queried to find out what songs were played on a given day,
or to find out what songs were played on a given station.

## Setup
start docker
`be docker-compose up -d`
set up the db
`be rake db:setup` create, load the schema and seed data into the database
Seeding is important to load the station(s)
run `bundle exec whenever --update-crontab` to create cronjobs to load the data
scrape broadcast titles for stations:
`be rake scrape:broadcast_titles STATION_ID=1`

## TO DO
[ ] Finish implementing Normalizable (see below)
[ ] Troubleshoot cronjobs and scheduler gem
[X] add fuzzy finder concern
[ ] implement fuzzy finder for artists, songs, albums, playlists, broadcasts, stations, record labels, genres
[ ] Create export to merge names in bulk
[ ] Add station timezone to stations table
  [ ] Factor in timezone when calculating air time
[ ] add broadcast first and last air date to broadcasts table
[x] scrape the broadcasts in chronological order to sort the IDs
[ ] create (or find!) a music dates API to check dates for music history events relevant to radio playlists
  - Maybe add ability to search by specific date (with year) or by month and day for any year and see playlists for that date
  - This would be for searching for non-holiday events. Adding a separate column for holidays.
  - It would also be nice to cross reference with a music history API to see what happened in music history on a playlist's air date.
  - Creating a music history calendar feels like a big undertaking that would quickly snowball. First I'll look in to these:
    - [ ] https://www.onthisday.com/music
    - [ ] https://www.thisdayinmusic.com/
    - [ ] https://www.songfacts.com/
    - [ ] https://www.musicvf.com/
    - [ ] https://www.music-map.com/
  - looking for:
    - album release dates
    - artist birthdays
    - artist death dates
[ ] also incorporate my previous logic for finding the playlists from the x week of a given month.
[ ] it might also be nice to create a calendar specific to each station
  [ ] station first broadcast/anniversary date
  [X] fund drives
  [ ] special events
[ ] Would it make sense to do the same for broadcasts?
    - first broadcast date and anniversary
    - ...special events?

### Future Normalizable Steps

Normalizable is implemented for Artists. Need to add to the following models.
Normalized columns and uniqueness indexes are already added to these:
- [ ] Album
- [ ] Broadcast
- [ ] Genre
- [ ] Playlist
- [ ] RecordLabel
- [ ] Song

#### Add to other normalized class models
For example:
```ruby
class Song < ApplicationRecord
  include Normalizable

  normalize_column :title, :normalized_title
end
```

#### Update queries to use normalized columns
```ruby
normalized_input = Normalizable.normalize_text("Beyoncé")
artist = Artist.find_by(normalized_name: normalized_input)
```

#### Correct data
Current data is not normalized. Some records will be invalid.
Need to create a `normalize_all` rake task to run `merge_duplicate_records` on each model.
If making changes to the Normalizable module, will need to do this again.

## DB Design
This is a bit out of date. I need to update it to reflect the current schema.
```yaml
Table stations {
  id integer [pk]
  name varchar
  call_sign varchar
  city varchar
  state varchar
  base_url varchar
  broadcasts_index_url varchar
  phone_number varchar
  text_number varchar
  email varchar
  frequencies jsonb
  created_at timestamp
}

  Table albums {
  id integer [pk]
  title varchar
  release_date date
  artist_id integer
  genre_id integer
  record_label_id integer
  created_at timestamp
}

  Table playlists {
  id integer [pk]
  title varchar
  air_date datetime
  station_id integer
  broadcast_id integer
  playlist_url varchar
  original_playlist_id integer
  download_url_1 varchar
  download_url_2 varchar
  scraped_data jsonb
  created_at timestamp
}

  Table record_labels {
  id integer [pk]
  name varchar
  created_at timestamp
}

  Table playlists_songs {
  id integer [pk]
  playlist_id integer
  song_id integer
  position integer
  air_date datetime
  created_at timestamp
}

  Table genres {
  id integer [pk]
  name varchar
  created_at timestamp
}

  Table artists {
  id integer [pk]
  name varchar
  bio text
  created_at timestamp
}

  Table songs {
  id integer [pk]
  title varchar
  duration integer
  album_id integer
  genre_id integer
  created_at timestamp
}

  Table artists_songs {
  artist_id integer
  song_id integer
  role varchar [note: 'e.g., Main, Featured']
  created_at timestamp
}

  Table albums_songs {
  album_id integer
  song_id integer
  created_at timestamp
}

  Table albums_artists {
  album_id integer
  artist_id integer
  created_at timestamp
}

  Table broadcasts {
  id integer [pk]
  station_id integer
  title varchar
  old_title varchar
  url varchar
  dj_names varchar
  dj_profile_url varchar
  dj_bio text
  air_day integer
  air_time_start time
  air_time_end time
}

Ref: albums_artists.album_id > albums.id
Ref: albums_songs.album_id > albums.id
Ref: albums_songs.song_id > songs.id
Ref: artists_songs.artist_id > artists.id
Ref: artists_songs.song_id > songs.id
Ref: playlists.station_id > stations.id
Ref: songs.genre_id > genres.id
Ref: playlists_songs.playlist_id > playlists.id
Ref: playlists_songs.song_id > songs.id
Ref: albums.record_label_id > record_labels.id
Ref: playlists.original_playlist_id > playlists.id
Ref: broadcasts.station_id > stations.id 
Ref: playlists.broadcast_id > broadcasts.id
```
