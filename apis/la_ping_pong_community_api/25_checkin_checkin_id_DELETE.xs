// Delete checkin record.
query "checkin/{checkin_id}" verb=DELETE {
  api_group = "LA Ping Pong Community API"

  input {
    int checkin_id? filters=min:1
  }

  stack {
    db.del checkin {
      field_name = "id"
      field_value = $input.checkin_id
    }
  }

  response = null
}