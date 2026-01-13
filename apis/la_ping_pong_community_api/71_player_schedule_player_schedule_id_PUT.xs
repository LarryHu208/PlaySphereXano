// Update player_schedule record
query "player_schedule/{player_schedule_id}" verb=PUT {
  api_group = "LA Ping Pong Community API"

  input {
    int player_schedule_id? filters=min:1
    dblink {
      table = "player_schedule"
    }
  }

  stack {
    db.edit player_schedule {
      field_name = "id"
      field_value = $input.player_schedule_id
      data = {
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