// Get user_schedule record
query "user_schedule/{user_schedule_id}" verb=GET {
  api_group = "LA Ping Pong Community API"

  input {
    int user_schedule_id? filters=min:1
  }

  stack {
    db.get user_schedule {
      field_name = "id"
      field_value = $input.user_schedule_id
    } as $model
  
    precondition ($model != null) {
      error_type = "notfound"
      error = "Not Found"
    }
  }

  response = $model
}