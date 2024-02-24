# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

## DB Design
```yaml
Table stations {
  id integer [pk]
  name varchar
  call_sign varchar
  location varchar
  created_at timestamp
}

  Table albums {
  id integer [pk]
  title varchar
  release_date date
  record_label_id integer
  created_at timestamp
}

  Table djs {
  id integer [pk]
  name varchar
  bio text
  created_at timestamp
}

  Table playlists {
  id integer [pk]
  title varchar
  air_date datetime
  dj_id integer
  station_id integer
  original_playlist_id integer
  playlist_url varchar
  download_url_1 varchar
  download_url_2 varchar
  scraped_data jsonb
  created_at timestamp
}

  Table record_labels {
  id integer [pk]
  name varchar

}

  Table playlists_songs {
  id integer [pk]
  playlist_id integer
  song_id integer
  position integer
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

Ref: albums_artists.album_id > albums.id
Ref: albums_songs.album_id > albums.id
Ref: albums_songs.song_id > songs.id
Ref: artists_songs.artist_id > artists.id
Ref: artists_songs.song_id > songs.id
Ref: playlists.dj_id > djs.id
Ref: playlists.station_id > stations.id
Ref: songs.genre_id > genres.id
Ref: playlists_songs.playlist_id > playlists.id
Ref: playlists_songs.song_id > songs.id
Ref: albums.record_label_id > record_labels.id
Ref: playlists.original_playlist_id > playlists.id



```