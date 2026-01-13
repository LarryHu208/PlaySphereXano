// Delete user_home_club record
query "user_home_club/{user_home_club_id}" verb=DELETE {
  api_group = "LA Ping Pong Community API"

  input {
    int user_home_club_id? filters=min:1
  }

  stack {
    db.del user_home_club {
      field_name = "id"
      field_value = $input.user_home_club_id
    }
  }

  response = null
}