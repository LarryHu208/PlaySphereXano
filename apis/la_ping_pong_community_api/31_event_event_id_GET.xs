// Get event record
query "event/{event_id}" verb=GET {
  api_group = "LA Ping Pong Community API"

  input {
    int event_id? filters=min:1
  }

  stack {
    db.get event {
      field_name = "id"
      field_value = $input.event_id
    } as $event
  
    precondition ($event != null) {
      error_type = "notfound"
      error = "Not Found."
    }
  }

  response = $event
}