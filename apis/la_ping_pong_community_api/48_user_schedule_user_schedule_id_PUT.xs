// Update user_schedule record
query "user_schedule/{user_schedule_id}" verb=PUT {
  api_group = "LA Ping Pong Community API"

  input {
    int user_schedule_id? filters=min:1
    dblink {
      table = "user_schedule"
    }
  }

  stack {
    db.edit user_schedule {
      field_name = "id"
      field_value = $input.user_schedule_id
      data = {
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