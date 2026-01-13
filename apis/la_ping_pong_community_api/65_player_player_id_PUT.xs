// Update player record
query "player/{player_id}" verb=PUT {
  api_group = "LA Ping Pong Community API"

  input {
    int player_id? filters=min:1
    dblink {
      table = "player"
    }
  }

  stack {
    db.edit player {
      field_name = "id"
      field_value = $input.player_id
      data = {
        display_name: $input.display_name
        rating      : $input.rating
        level_tag   : $input.level_tag
        bio         : $input.bio
        style       : $input.style
        source      : $input.source
        is_active   : $input.is_active
      }
    } as $model
  }

  response = $model
}