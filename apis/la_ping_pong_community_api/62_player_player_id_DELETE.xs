// Delete player record
query "player/{player_id}" verb=DELETE {
  api_group = "LA Ping Pong Community API"

  input {
    int player_id? filters=min:1
  }

  stack {
    db.del player {
      field_name = "id"
      field_value = $input.player_id
    }
  }

  response = null
}