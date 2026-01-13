// Get player_schedule record
query "player_schedule/{player_schedule_id}" verb=GET {
  api_group = "LA Ping Pong Community API"

  input {
    int player_schedule_id? filters=min:1
  }

  stack {
    db.get player_schedule {
      field_name = "id"
      field_value = $input.player_schedule_id
    } as $model
  
    precondition ($model != null) {
      error_type = "notfound"
      error = "Not Found"
    }
  }

  response = $model
}