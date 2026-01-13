// Get user_home_club record
query "user_home_club/{user_home_club_id}" verb=GET {
  api_group = "LA Ping Pong Community API"

  input {
    int user_home_club_id? filters=min:1
  }

  stack {
    db.get user_home_club {
      field_name = "id"
      field_value = $input.user_home_club_id
    } as $model
  
    precondition ($model != null) {
      error_type = "notfound"
      error = "Not Found"
    }
  }

  response = $model
}