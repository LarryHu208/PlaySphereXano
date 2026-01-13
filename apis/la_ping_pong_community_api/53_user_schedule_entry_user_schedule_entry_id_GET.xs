// Get user_schedule_entry record
query "user_schedule_entry/{user_schedule_entry_id}" verb=GET {
  api_group = "LA Ping Pong Community API"

  input {
    int user_schedule_entry_id? filters=min:1
  }

  stack {
    db.get user_schedule_entry {
      field_name = "id"
      field_value = $input.user_schedule_entry_id
    } as $model
  
    precondition ($model != null) {
      error_type = "notfound"
      error = "Not Found"
    }
  }

  response = $model
}