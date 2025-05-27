# Playlist API - Future Enhancement Ideas

This document outlines potential future endpoints and features for the playlist API.

## Potential Endpoints

### Filter Playlists by Genre
```ruby
def by_genre
  genre_id = params[:genre_id]
  playlists = Playlist.joins(songs: :genre)
                      .where(songs: { genre_id: genre_id })
                      .distinct
                      .order(air_date: :desc)
                      .limit(20)
  render json: { playlists: playlists }
end
```

### Playlists by Week of Month
```ruby
def by_week_of_month
  # Get playlists for a specific week number (1-5) of a specific month
  month = params[:month].to_i
  week = params[:week].to_i
  year = params[:year]&.to_i || Date.today.year
  
  # Calculate date range for the specified week of month
  first_day_of_month = Date.new(year, month, 1)
  start_of_week = first_day_of_month + ((week - 1) * 7)
  end_of_week = start_of_week + 6
  
  playlists = Playlist.where(air_date: start_of_week.beginning_of_day..end_of_week.end_of_day)
                      .order(air_date: :asc)
                      
  render json: { playlists: playlists }
end
```

### Playlists with Multiple Artists
```ruby
def with_multiple_artists
  # Find playlists with songs from multiple specified artists
  artist_ids = params[:artist_ids].split(',').map(&:to_i)
  
  # This requires more complex SQL to find playlists that include ALL specified artists
  playlists = Playlist.joins(songs: :artist)
                     .where(songs: { artist_id: artist_ids })
                     .group('playlists.id')
                     .having('COUNT(DISTINCT songs.artist_id) = ?', artist_ids.length)
                     
  render json: { playlists: playlists }
end
```

### Holiday Playlists
```ruby
def holiday_playlists
  holiday = params[:holiday]
  playlists = Playlist.where("holiday ILIKE ?", "%#{holiday}%")
                      .order(air_date: :desc)
                      
  render json: { playlists: playlists }
end
```

### Fund Drive Playlists
```ruby
def fund_drive_playlists
  playlists = Playlist.where(fund_drive: true)
                      .order(air_date: :desc)
                      
  render json: { playlists: playlists }
end
```

## Potential Features

1. **Playlist Statistics**
   - Most played artists per week/month/year
   - Most played songs per week/month/year
   - Average songs per playlist by broadcast

2. **Music History Integration**
   - Enhance playlists with music history events that occurred on the same date
   - Include artist birthdays and anniversaries
   - Show album release anniversaries

3. **Related Playlists**
   - Find similar playlists by song/artist overlap
   - Recommend playlists based on listening history

4. **Playlist Exports**
   - Generate Spotify/Apple Music compatible playlist files
   - Export playlists to CSV

5. **Advanced Filtering**
   - Filter playlists by release decade of songs
   - Filter by multiple genres
   - Filter by DJ

## Implementation Considerations

- Use pagination for large result sets
- Consider caching popular queries
- Add response compression for bandwidth optimization
- Add query timeouts for complex filtering operations
