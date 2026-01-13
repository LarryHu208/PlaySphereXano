// Get player_schedule_entry record
query "player_schedule_entry/{player_schedule_entry_id}" verb=GET {
  api_group = "LA Ping Pong Community API"

  input {
    int player_schedule_entry_id? filters=min:1
  }

  stack {
    db.get player_schedule_entry {
      field_name = "id"
      field_value = $input.player_schedule_entry_id
    } as $model
  
    precondition ($model != null) {
      error_type = "notfound"
      error = "Not Found"
    }
  }

  response = $model
}