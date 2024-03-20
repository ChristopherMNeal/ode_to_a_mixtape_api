# frozen_string_literal: true

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

ActiveRecord::Schema[7.1].define(version: 20_240_317_034_843) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "albums", force: :cascade do |t|
    t.string "title"
    t.date "release_date"
    t.bigint "artist_id"
    t.bigint "genre_id"
    t.bigint "record_label_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["artist_id"], name: "index_albums_on_artist_id"
    t.index ["genre_id"], name: "index_albums_on_genre_id"
    t.index ["record_label_id"], name: "index_albums_on_record_label_id"
  end

  create_table "albums_artists", force: :cascade do |t|
    t.bigint "album_id", null: false
    t.bigint "artist_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index %w[album_id artist_id], name: "index_albums_artists_on_album_id_and_artist_id", unique: true
    t.index ["album_id"], name: "index_albums_artists_on_album_id"
    t.index ["artist_id"], name: "index_albums_artists_on_artist_id"
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
  end

  create_table "broadcasts", force: :cascade do |t|
    t.bigint "station_id"
    t.bigint "dj_id"
    t.string "title"
    t.string "old_title"
    t.string "url"
    t.integer "air_day"
    t.time "air_time_start"
    t.time "air_time_end"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["dj_id"], name: "index_broadcasts_on_dj_id"
    t.index ["station_id"], name: "index_broadcasts_on_station_id"
    t.index ["title"], name: "index_broadcasts_on_title"
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
  end

  create_table "playlists", force: :cascade do |t|
    t.string "title"
    t.datetime "air_date"
    t.bigint "station_id"
    t.bigint "broadcast_id"
    t.string "playlist_url"
    t.integer "original_playlist_id"
    t.string "download_url_1"
    t.string "download_url_2"
    t.jsonb "scraped_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["broadcast_id"], name: "index_playlists_on_broadcast_id"
    t.index ["station_id"], name: "index_playlists_on_station_id"
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
  end

  create_table "songs", force: :cascade do |t|
    t.string "title"
    t.integer "duration"
    t.bigint "artist_id"
    t.bigint "genre_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["artist_id"], name: "index_songs_on_artist_id"
    t.index ["genre_id"], name: "index_songs_on_genre_id"
    t.index ["title"], name: "index_songs_on_title"
  end

  create_table "stations", force: :cascade do |t|
    t.string "name"
    t.string "call_sign"
    t.string "city"
    t.string "state"
    t.string "base_url"
    t.string "broadcasts_index_url"
    t.string "phone_number"
    t.string "text_number"
    t.string "email"
    t.jsonb "frequencies"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "albums", "artists"
  add_foreign_key "albums", "genres"
  add_foreign_key "albums", "record_labels"
  add_foreign_key "albums_artists", "albums"
  add_foreign_key "albums_artists", "artists"
  add_foreign_key "albums_songs", "albums"
  add_foreign_key "albums_songs", "songs"
  add_foreign_key "broadcasts", "djs"
  add_foreign_key "broadcasts", "stations"
  add_foreign_key "djs_stations", "djs"
  add_foreign_key "djs_stations", "stations"
  add_foreign_key "playlists", "broadcasts"
  add_foreign_key "playlists", "playlists", column: "original_playlist_id"
  add_foreign_key "playlists", "stations"
  add_foreign_key "playlists_songs", "playlists"
  add_foreign_key "playlists_songs", "songs"
  add_foreign_key "songs", "artists"
  add_foreign_key "songs", "genres"
end
