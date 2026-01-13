// Query all club records
query club verb=GET {
  api_group = "LA Ping Pong Community API"

  input {
  }

  stack {
    db.query club {
      return = {type: "list"}
    } as $club
  }

  response = $club
}