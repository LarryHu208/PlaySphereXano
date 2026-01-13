// Edit player record
query "player/{player_id}" verb=PATCH {
  api_group = "LA Ping Pong Community API"

  input {
    int player_id? filters=min:1
    dblink {
      table = "player"
    }
  }

  stack {
    util.get_raw_input {
      encoding = "json"
      exclude_middleware = false
    } as $raw_input
  
    db.patch player {
      field_name = "id"
      field_value = $input.player_id
      data = `$input|pick:($raw_input|keys)`|filter_null|filter_empty_text
    } as $model
  }

  response = $model
}