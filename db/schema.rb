# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_03_22_134558) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_trgm"
  enable_extension "plpgsql"
  enable_extension "unaccent"

  create_table "albums", force: :cascade do |t|
    t.string "title"
    t.date "release_date"
    t.bigint "artist_id"
    t.bigint "genre_id"
    t.bigint "record_label_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "normalized_title"
    t.index ["artist_id", "normalized_title"], name: "index_albums_on_artist_id_and_normalized_title", unique: true
    t.index ["artist_id", "title"], name: "index_albums_on_artist_id_and_title", unique: true
    t.index ["artist_id"], name: "index_albums_on_artist_id"
    t.index ["genre_id"], name: "index_albums_on_genre_id"
    t.index ["record_label_id"], name: "index_albums_on_record_label_id"
  end

  create_table "albums_songs", force: :cascade do |t|
    t.bigint "album_id", null: false
    t.bigint "song_id", null: false
    t.integer "track_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["album_id"], name: "index_albums_songs_on_album_id"
    t.index ["song_id"], name: "index_albums_songs_on_song_id"
  end

  create_table "artists", force: :cascade do |t|
    t.string "name"
    t.text "bio"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "normalized_name"
    t.index ["normalized_name"], name: "index_artists_on_normalized_name", unique: true
  end

  create_table "broadcasts", force: :cascade do |t|
    t.bigint "station_id", null: false
    t.bigint "dj_id"
    t.string "title", null: false
    t.string "old_title"
    t.string "url", null: false
    t.integer "air_day"
    t.time "air_time_start"
    t.time "air_time_end"
    t.boolean "active", default: true
    t.datetime "last_scraped_at"
    t.integer "frequency_in_days"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "normalized_title"
    t.index ["dj_id"], name: "index_broadcasts_on_dj_id"
    t.index ["normalized_title"], name: "index_broadcasts_on_normalized_title"
    t.index ["station_id"], name: "index_broadcasts_on_station_id"
    t.index ["title"], name: "index_broadcasts_on_title"
    t.index ["url"], name: "index_broadcasts_on_url", unique: true
    t.check_constraint "air_day IS NULL OR air_day >= 0 AND air_day <= 6", name: "air_day_valid_range"
  end

  create_table "djs", force: :cascade do |t|
    t.string "dj_name"
    t.string "member_names"
    t.text "bio"
    t.string "email"
    t.string "twitter"
    t.string "instagram"
    t.string "facebook"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "djs_stations", force: :cascade do |t|
    t.bigint "dj_id", null: false
    t.bigint "station_id", null: false
    t.string "profile_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dj_id"], name: "index_djs_stations_on_dj_id"
    t.index ["station_id"], name: "index_djs_stations_on_station_id"
  end

  create_table "genres", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "normalized_name"
    t.index ["normalized_name"], name: "index_genres_on_normalized_name", unique: true
  end

  create_table "playlist_imports", force: :cascade do |t|
    t.bigint "playlist_id", null: false
    t.jsonb "scraped_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["playlist_id"], name: "index_playlist_imports_on_playlist_id"
  end

  create_table "playlists", force: :cascade do |t|
    t.string "title"
    t.datetime "air_date"
    t.bigint "station_id"
    t.bigint "broadcast_id"
    t.string "playlist_url", null: false
    t.integer "original_playlist_id"
    t.string "download_url_1"
    t.string "download_url_2"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "theme"
    t.string "holiday"
    t.boolean "fund_drive", default: false, null: false
    t.string "normalized_title"
    t.index "lower((playlist_url)::text)", name: "index_playlists_on_lower_playlist_url", unique: true
    t.index ["broadcast_id"], name: "index_playlists_on_broadcast_id"
    t.index ["holiday"], name: "index_playlists_on_holiday"
    t.index ["normalized_title"], name: "index_playlists_on_normalized_title"
    t.index ["station_id"], name: "index_playlists_on_station_id"
    t.index ["theme"], name: "index_playlists_on_theme"
  end

  create_table "playlists_songs", force: :cascade do |t|
    t.bigint "playlist_id", null: false
    t.bigint "song_id", null: false
    t.integer "position"
    t.datetime "air_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["playlist_id"], name: "index_playlists_songs_on_playlist_id"
    t.index ["song_id"], name: "index_playlists_songs_on_song_id"
  end

  create_table "record_labels", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "normalized_name"
    t.index ["normalized_name"], name: "index_record_labels_on_normalized_name", unique: true
  end

  create_table "songs", force: :cascade do |t|
    t.string "title"
    t.integer "duration"
    t.bigint "artist_id"
    t.bigint "genre_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "normalized_title"
    t.index ["artist_id", "normalized_title"], name: "index_songs_on_artist_id_and_normalized_title", unique: true
    t.index ["artist_id", "title"], name: "index_songs_on_artist_id_and_title", unique: true
    t.index ["artist_id"], name: "index_songs_on_artist_id"
    t.index ["genre_id"], name: "index_songs_on_genre_id"
  end

  create_table "stations", force: :cascade do |t|
    t.string "name", null: false
    t.string "call_sign"
    t.string "city"
    t.string "state"
    t.string "base_url", null: false
    t.string "broadcasts_index_url", null: false
    t.string "phone_number"
    t.string "text_number"
    t.string "email"
    t.jsonb "frequencies"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["base_url"], name: "index_stations_on_base_url", unique: true
    t.index ["broadcasts_index_url"], name: "index_stations_on_broadcasts_index_url", unique: true
    t.index ["call_sign"], name: "index_stations_on_call_sign", unique: true
    t.index ["name"], name: "index_stations_on_name", unique: true
  end

  add_foreign_key "albums", "artists"
  add_foreign_key "albums", "genres"
  add_foreign_key "albums", "record_labels"
  add_foreign_key "albums_songs", "albums"
  add_foreign_key "albums_songs", "songs"
  add_foreign_key "broadcasts", "djs"
  add_foreign_key "broadcasts", "stations"
  add_foreign_key "djs_stations", "djs"
  add_foreign_key "djs_stations", "stations"
  add_foreign_key "playlist_imports", "playlists"
  add_foreign_key "playlists", "broadcasts"
  add_foreign_key "playlists", "playlists", column: "original_playlist_id"
  add_foreign_key "playlists", "stations"
  add_foreign_key "playlists_songs", "playlists"
  add_foreign_key "playlists_songs", "songs"
  add_foreign_key "songs", "artists"
  add_foreign_key "songs", "genres"
end
