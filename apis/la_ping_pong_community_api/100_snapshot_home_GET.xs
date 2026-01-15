// Returns a snapshot of clubs, events, and statistics: including player counts, club counts, and session counts
query "snapshot/home" verb=GET {
  api_group = "LA Ping Pong Community API"

  input {
  }

  stack {
    // 1) Get list of clubs
    db.query club {
      return = {type: "list"}
    } as $clubs
  
    // 2) Get list of events
    db.query event {
      return = {type: "list"}
    } as $events
  
    // 3.1) Get count of clubs
    db.query club {
      return = {type: "count"}
    } as $club_count
  
    // 3.2) Get count of players
    db.query player {
      return = {type: "count"}
    } as $player_count
  
    // 3.3) Get all schedule entries (full rows; Xano does not support select)
    db.query player_schedule_entry {
      return = {type: "list"}
    } as $entries
  
    // 3.4) Get all schedule entries (full rows; Xano does not support select)
    db.query checkin {
      return = {type: "count"}
    } as $checkin_count
  
    // 4) Compute total sessions via bitcount(days_mask)
    api.lambda {
      code = """
          let total = 0;
          const entries = $var.entries || [];
          for (const entry of entries) {
            let mask = entry.days_mask || 0;
            while (mask > 0) {
              total += (mask & 1);
              mask >>= 1;
            }
          }
          return total;
        """
      timeout = 10
    } as $total_sessions
  }

  response = {
    generated_at: now
    clubs       : $clubs
    events      : $events
    stats       : ```
      {
        total_clubs: $club_count
        total_players: $player_count
        total_sessions: $total_sessions
        total_checkins: $checkin_count
      }
      ```
  }

  tags = ["snapshot", "ping pong"]
}