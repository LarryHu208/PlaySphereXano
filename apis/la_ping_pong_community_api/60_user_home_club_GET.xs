// Query all user_home_club records
query user_home_club verb=GET {
  api_group = "LA Ping Pong Community API"

  input {
  }

  stack {
    db.query user_home_club {
      return = {type: "list"}
    } as $model
  }

  response = $model
}