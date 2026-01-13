// Add user_home_club record
query user_home_club verb=POST {
  api_group = "LA Ping Pong Community API"

  input {
    dblink {
      table = "user_home_club"
    }
  }

  stack {
    db.add user_home_club {
      data = {
        created_at: "now"
        user_id   : $input.user_id
        club_id   : $input.club_id
      }
    } as $model
  }

  response = $model
}