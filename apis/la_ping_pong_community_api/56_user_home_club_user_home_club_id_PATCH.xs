// Edit user_home_club record
query "user_home_club/{user_home_club_id}" verb=PATCH {
  api_group = "LA Ping Pong Community API"

  input {
    int user_home_club_id? filters=min:1
    dblink {
      table = "user_home_club"
    }
  }

  stack {
    util.get_raw_input {
      encoding = "json"
      exclude_middleware = false
    } as $raw_input
  
    db.patch user_home_club {
      field_name = "id"
      field_value = $input.user_home_club_id
      data = `$input|pick:($raw_input|keys)`|filter_null|filter_empty_text
    } as $model
  }

  response = $model
}