// Query all user_schedule records
query user_schedule verb=GET {
  api_group = "LA Ping Pong Community API"

  input {
  }

  stack {
    db.query user_schedule {
      return = {type: "list"}
    } as $model
  }

  response = $model
}