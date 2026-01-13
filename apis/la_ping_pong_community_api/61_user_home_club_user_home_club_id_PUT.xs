// Update user_home_club record
query "user_home_club/{user_home_club_id}" verb=PUT {
  api_group = "LA Ping Pong Community API"

  input {
    int user_home_club_id? filters=min:1
    dblink {
      table = "user_home_club"
    }
  }

  stack {
    db.edit user_home_club {
      field_name = "id"
      field_value = $input.user_home_club_id
      data = {user_id: $input.user_id, club_id: $input.club_id}
    } as $model
  }

  response = $model
}