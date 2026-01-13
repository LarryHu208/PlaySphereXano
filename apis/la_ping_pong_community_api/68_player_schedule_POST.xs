// Add player_schedule record
query player_schedule verb=POST {
  api_group = "LA Ping Pong Community API"

  input {
    dblink {
      table = "player_schedule"
    }
  }

  stack {
    db.add player_schedule {
      data = {
        created_at     : "now"
        player_id      : $input.player_id
        default_club_id: $input.default_club_id
        timezone       : $input.timezone
        active         : $input.active
        updated_at     : $input.updated_at
      }
    } as $model
  }

  response = $model
}