// Get the total count of clubs
query "stats/club/count" verb=GET {
  api_group = "LA Ping Pong Community API"

  input {
  }

  stack {
    db.query club {
      return = {type: "count"}
    } as $count
  }

  response = {total_clubs: $count}
}