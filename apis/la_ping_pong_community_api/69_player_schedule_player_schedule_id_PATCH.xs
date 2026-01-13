// Edit player_schedule record
query "player_schedule/{player_schedule_id}" verb=PATCH {
  api_group = "LA Ping Pong Community API"

  input {
    int player_schedule_id? filters=min:1
    dblink {
      table = "player_schedule"
    }
  }

  stack {
    util.get_raw_input {
      encoding = "json"
      exclude_middleware = false
    } as $raw_input
  
    db.patch player_schedule {
      field_name = "id"
      field_value = $input.player_schedule_id
      data = `$input|pick:($raw_input|keys)`|filter_null|filter_empty_text
    } as $model
  }

  response = $model
}