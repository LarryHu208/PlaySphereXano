// Get the total count of players
query "stats/player/count" verb=GET {
  api_group = "LA Ping Pong Community API"

  input {
  }

  stack {
    db.query player {
      return = {type: "count"}
    } as $count
  }

  response = {total_players: $count}
}