// Delete player_schedule record
query "player_schedule/{player_schedule_id}" verb=DELETE {
  api_group = "LA Ping Pong Community API"

  input {
    int player_schedule_id? filters=min:1
  }

  stack {
    db.del player_schedule {
      field_name = "id"
      field_value = $input.player_schedule_id
    }
  }

  response = null
}