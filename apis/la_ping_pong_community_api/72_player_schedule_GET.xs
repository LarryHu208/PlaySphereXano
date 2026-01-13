// Query all player_schedule records
query player_schedule verb=GET {
  api_group = "LA Ping Pong Community API"

  input {
  }

  stack {
    db.query player_schedule {
      return = {type: "list"}
    } as $model
  }

  response = $model
}