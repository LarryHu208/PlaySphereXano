// Query all player_schedule_entry records
query player_schedule_entry verb=GET {
  api_group = "LA Ping Pong Community API"

  input {
  }

  stack {
    db.query player_schedule_entry {
      return = {type: "list"}
    } as $model
  }

  response = $model
}