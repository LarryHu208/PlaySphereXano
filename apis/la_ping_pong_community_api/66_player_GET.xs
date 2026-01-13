// Query all player records
query player verb=GET {
  api_group = "LA Ping Pong Community API"

  input {
  }

  stack {
    db.query player {
      return = {type: "list"}
    } as $model
  }

  response = $model
}