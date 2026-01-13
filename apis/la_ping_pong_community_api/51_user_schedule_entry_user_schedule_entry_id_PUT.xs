// Update user_schedule_entry record
query "user_schedule_entry/{user_schedule_entry_id}" verb=PUT {
  api_group = "LA Ping Pong Community API"

  input {
    int user_schedule_entry_id? filters=min:1
    dblink {
      table = "user_schedule_entry"
    }
  }

  stack {
    db.edit user_schedule_entry {
      field_name = "id"
      field_value = $input.user_schedule_entry_id
      data = {
        schedule_id: $input.schedule_id
        day_of_week: $input.day_of_week
        start_time : $input.start_time
        end_time   : $input.end_time
        club_id    : $input.club_id
        notes      : $input.notes
        confidence : $input.confidence
      }
    } as $model
  }

  response = $model
}