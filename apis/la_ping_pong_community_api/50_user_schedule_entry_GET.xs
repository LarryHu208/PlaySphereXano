// Query all user_schedule_entry records
query user_schedule_entry verb=GET {
  api_group = "LA Ping Pong Community API"

  input {
  }

  stack {
    db.query user_schedule_entry {
      return = {type: "list"}
    } as $model
  }

  response = $model
}