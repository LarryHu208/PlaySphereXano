// Delete user_schedule record
query "user_schedule/{user_schedule_id}" verb=DELETE {
  api_group = "LA Ping Pong Community API"

  input {
    int user_schedule_id? filters=min:1
  }

  stack {
    db.del user_schedule {
      field_name = "id"
      field_value = $input.user_schedule_id
    }
  }

  response = null
}