// Edit user_schedule record
query "user_schedule/{user_schedule_id}" verb=PATCH {
  api_group = "LA Ping Pong Community API"

  input {
    int user_schedule_id? filters=min:1
    dblink {
      table = "user_schedule"
    }
  }

  stack {
    util.get_raw_input {
      encoding = "json"
      exclude_middleware = false
    } as $raw_input
  
    db.patch user_schedule {
      field_name = "id"
      field_value = $input.user_schedule_id
      data = `$input|pick:($raw_input|keys)`|filter_null|filter_empty_text
    } as $model
  }

  response = $model
}