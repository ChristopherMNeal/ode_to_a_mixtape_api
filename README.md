# README
## TO DO
- [] Add station timezone to stations table
  - [] Factor in timezone when calculating air time
- [] add broadcast first and last air date to broadcasts table
- [] scrape the broadcasts in chronological order to sort the IDs

## DB Design
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