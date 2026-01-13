// Add player_schedule_entry record
query player_schedule_entry verb=POST {
  api_group = "LA Ping Pong Community API"

  input {
    dblink {
      table = "player_schedule_entry"
    }
  }

  stack {
    db.add player_schedule_entry {
      data = {
        created_at : "now"
        schedule_id: $input.schedule_id
        day_of_week: $input.day_of_week
        start_time : $input.start_time
        end_time   : $input.end_time
        club_id    : $input.club_id
        notes      : $input.notes
        confidence : $input.confidence
      }
    } as $model
  }

  response = $model
}