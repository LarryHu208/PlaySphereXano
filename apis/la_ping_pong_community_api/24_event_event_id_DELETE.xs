// Delete event record.
query "event/{event_id}" verb=DELETE {
  api_group = "LA Ping Pong Community API"

  input {
    int event_id? filters=min:1
  }

  stack {
    db.del event {
      field_name = "id"
      field_value = $input.event_id
    }
  }

  response = null
}