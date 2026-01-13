// Add player record
query player verb=POST {
  api_group = "LA Ping Pong Community API"

  input {
    dblink {
      table = "player"
    }
  }

  stack {
    db.add player {
      data = {
        created_at  : "now"
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