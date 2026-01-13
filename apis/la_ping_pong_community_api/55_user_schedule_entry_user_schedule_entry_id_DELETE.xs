// Delete user_schedule_entry record
query "user_schedule_entry/{user_schedule_entry_id}" verb=DELETE {
  api_group = "LA Ping Pong Community API"

  input {
    int user_schedule_entry_id? filters=min:1
  }

  stack {
    db.del user_schedule_entry {
      field_name = "id"
      field_value = $input.user_schedule_entry_id
    }
  }

  response = null
}