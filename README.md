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

## API Documentation
### Base URL
All API endpoints are relative to: `/api/v1/`

### Response Format
All responses are returned in JSON format with appropriate HTTP status codes.
List endpoints wrap their results in a root key (e.g., `{ "artists": [...] }`).
Detail endpoints include the main resource and its associations as separate top-level keys.

### Endpoints

#### Playlists
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/playlists` | Get the 20 most recent playlists (excluding rebroadcasts) |
| GET | `/playlists/:id` | Get a specific playlist with associated songs, broadcast, and station |
| GET | `/playlists/by_broadcast/:broadcast_id` | Get playlists for a specific broadcast |
| GET | `/playlists/by_date` | Get playlists within a date range |
| GET | `/playlists/random` | Get a random playlist with its songs, broadcast, and station |
| GET | `/playlists/find` | Find playlists featuring a specific artist or song |
| GET | `/playlists/on_this_day` | Find playlists from the same calendar date across all years |

**Parameters for `/playlists/by_date`:**
- `start_date` (required): Start date in YYYY-MM-DD format
- `end_date` (optional): End date in YYYY-MM-DD format (defaults to current date)

**Parameters for `/playlists/find`:**
- Either `artist_id` or `song_id` (required): ID of the artist or song to search for

**Parameters for `/playlists/on_this_day`:**
- `month` (optional): Month as an integer (1-12, defaults to current month)
- `day` (optional): Day as an integer (1-31, defaults to current day)

#### Artists
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/artists` | Get up to 50 artists ordered by name |
| GET | `/artists/:id` | Get a specific artist with their songs and albums |
| GET | `/artists/search` | Search for artists by name |
| GET | `/artists/:id/playlists` | Get playlists featuring a specific artist |

**Parameters for `/artists/search`:**
- `q` (optional): Search query string. If not provided, returns the 20 most recent artists.

#### Songs
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/songs` | Get the 50 most recent songs with their artists |
| GET | `/songs/:id` | Get a specific song with its artist, albums, and playlists |
| GET | `/songs/search` | Search for songs by title |

**Parameters for `/songs/search`:**
- `q` (optional): Search query string. If not provided, returns the 20 most recent songs.

#### Broadcasts
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/broadcasts` | Get all active broadcasts ordered by title |
| GET | `/broadcasts/:id` | Get a specific broadcast with its station, playlists, and DJ |
| GET | `/broadcasts/by_station/:station_id` | Get broadcasts for a specific station |
| GET | `/broadcasts/by_day/:day` | Get broadcasts for a specific day of the week |

**Parameters for `/broadcasts/by_day/:day`:**
- `day` (required): Day of the week as an integer (0-6, where 0 is Sunday)

#### Stations
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/stations` | Get all stations |
| GET | `/stations/:id` | Get a specific station with its broadcasts |

#### Search
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/search` | Unified search across multiple models |
| GET | `/fuzzy_search` | Fuzzy search within a specific model |

**Parameters for `/search`:**
- `q` (required): Search query string

**Parameters for `/fuzzy_search`:**
- `q` (required): Search query string
- `model` (required): Model name to search (e.g., 'artist', 'song', 'album', 'broadcast')
- `column` (optional): Column to search within (defaults to 'name')
- `threshold` (optional): Similarity threshold from 0.0 to 1.0 (defaults to 0.6)

**Example Response for `/search`:**
```json
{
  "artists": [
    {"id": 1, "name": "Miles Davis"},
    {"id": 2, "name": "Dave Matthews Band"}
  ],
  "songs": [
    {"id": 10, "title": "So What", "artist": {"id": 1, "name": "Miles Davis"}},
    {"id": 11, "title": "All Blues", "artist": {"id": 1, "name": "Miles Davis"}}
  ],
  "albums": [
    {"id": 5, "title": "Kind of Blue", "artist": {"id": 1, "name": "Miles Davis"}},
    {"id": 6, "title": "Crash", "artist": {"id": 2, "name": "Dave Matthews Band"}}
  ],
  "broadcasts": [
    {"id": 20, "title": "Miles of Jazz", "station": {"id": 1, "name": "WWOZ"}}
  ]
}

### Example Responses

#### Get a Playlist
```json
{
  "playlist": {
    "id": 123,
    "title": "Evening Jazz",
    "air_date": "2025-05-20T20:00:00Z",
    "playlist_url": "https://example.com/playlist/123",
    "theme": "Jazz Classics",
    "holiday": null,
    "fund_drive": false
  },
  "songs": [
    {"id": 1, "title": "So What", "duration": 565},
    {"id": 2, "title": "Take Five", "duration": 325}
  ],
  "broadcast": {
    "id": 45,
    "title": "Jazz Hour",
    "active": true
  },
  "station": {
    "id": 5,
    "name": "WBGO",
    "call_sign": "WBGO"
  }
}
```

#### Search for Artists
```json
{
  "artists": [
    {"id": 1, "name": "Miles Davis", "bio": "..."},
    {"id": 2, "name": "Dave Brubeck", "bio": "..."}
  ]
}
```

#### Find Playlists By Artist
```json
{
  "playlists": [
    {
      "id": 456,
      "title": "Jazz Classics",
      "air_date": "2025-05-20T20:00:00Z",
      "broadcast": {
        "id": 42,
        "title": "Evening Jazz"
      },
      "station": {
        "id": 5,
        "name": "WBGO"
      }
    },
    {
      "id": 789,
      "title": "Legends of Jazz",
      "air_date": "2025-01-15T19:00:00Z",
      "broadcast": {
        "id": 43,
        "title": "Jazz Hour"
      },
      "station": {
        "id": 5,
        "name": "WBGO"
      }
    }
  ]
}
```

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
[X] Implement API endpoints
  [X] Random playlist
  [X] Find playlists with a specific artist/song
  [X] Playlists from this date in previous years
  [ ] lots more
[X] Finish implementing Normalizable (see below)
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
Done!

Normalizable is implemented for Artists. Need to add to the following models.
Normalized columns and uniqueness indexes are already added to these:
- [X] Album
- [X] Broadcast
- [X] Genre
- [X] Playlist
- [X] RecordLabel
- [X] Song

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
