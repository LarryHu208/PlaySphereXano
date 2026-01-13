// Get player record
query "player/{player_id}" verb=GET {
  api_group = "LA Ping Pong Community API"

  input {
    int player_id? filters=min:1
  }

  stack {
    db.get player {
      field_name = "id"
      field_value = $input.player_id
    } as $model
  
    precondition ($model != null) {
      error_type = "notfound"
      error = "Not Found"
    }
  }

  response = $model
}