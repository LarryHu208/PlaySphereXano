// Snapshot: players + schedules + entries for a club, plus total sessions (bitcount days_mask)
// Uses the same XanoScript style as your reference ( $db / $input / map:$this / contains )
query "snapshot/player_by_club" verb=GET {
  api_group = "LA Ping Pong Community API"

  input {
    int club_id
  }

  stack {
    // 1) Entries for this club
    db.query player_schedule_entry {
      where = $db.player_schedule_entry.club_id == $input.club_id
      return = {type: "list"}
    } as $entries
  
    // 2) Extract schedule_ids from entries
    api.lambda {
      code = """
          const entries = $var.entries || [];
          const ids = entries.map(e => e.schedule_id).filter(v => v != null);
          return [...new Set(ids)];
        """
      timeout = 5
    } as $entry_schedule_ids
  
    // 3a) Schedules where default club matches
    db.query player_schedule {
      where = $db.player_schedule.default_club_id == $input.club_id
      return = {type: "list"}
    } as $default_schedules
  
    // 3b) Schedules referenced by entries (only if there are ids)
    // If Xano errors on empty IN lists, this lambda ensures [] -> [0] (no match) safely.
    api.lambda {
      code = """
          const ids = $var.entry_schedule_ids || [];
          return ids.length ? ids : [0];
        """
      timeout = 3
    } as $safe_entry_schedule_ids
  
    db.query player_schedule {
      where = $db.player_schedule.id in $safe_entry_schedule_ids
      return = {type: "list"}
    } as $entry_schedules
  
    // 4) Merge schedules + dedupe by id
    api.lambda {
      code = """
          const a = $var.default_schedules || [];
          const b = $var.entry_schedules || [];
          const byId = new Map();
          for (const s of [...a, ...b]) byId.set(s.id, s);
          return Array.from(byId.values());
        """
      timeout = 5
    } as $schedules
  
    // 5) Extract player_ids from merged schedules
    api.lambda {
      code = """
          const schedules = $var.schedules || [];
          const ids = schedules.map(s => s.player_id).filter(v => v != null);
          return [...new Set(ids)];
        """
      timeout = 5
    } as $player_ids
  
    // 6) Fetch players
    api.lambda {
      code = """
          const ids = $var.player_ids || [];
          return ids.length ? ids : [0];
        """
      timeout = 3
    } as $safe_player_ids
  
    db.query player {
      where = $db.player.id in $safe_player_ids
      return = {type: "list"}
    } as $players
  
    // 7) Total sessions from days_mask
    api.lambda {
      code = """
          let total = 0;
          const entries = $var.entries || [];
          for (const e of entries) {
            let mask = e.days_mask || 0;
            while (mask > 0) { total += (mask & 1); mask >>= 1; }
          }
          return total;
        """
      timeout = 10
    } as $total_sessions
  }

  response = {
    club_id  : $input.club_id
    players  : $players
    schedules: $schedules
    entries  : $entries
    stats    : { total_sessions: $total_sessions }
  }

  tags = ["snapshot", "player"]
}