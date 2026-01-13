// Add user_schedule record
query user_schedule verb=POST {
  api_group = "LA Ping Pong Community API"

  input {
    dblink {
      table = "user_schedule"
    }
  }

  stack {
    db.add user_schedule {
      data = {
        created_at     : "now"
        user_id        : $input.user_id
        default_club_id: $input.default_club_id
        timezone       : $input.timezone
        active         : $input.active
        updated_at     : $input.updated_at
      }
    } as $model
  }

  response = $model
}