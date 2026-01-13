// Edit event record
query "event/{event_id}" verb=PATCH {
  api_group = "LA Ping Pong Community API"

  input {
    int event_id? filters=min:1
    dblink {
      table = "event"
    }
  }

  stack {
    util.get_raw_input {
      encoding = "json"
      exclude_middleware = false
    } as $raw_input
  
    db.patch event {
      field_name = "id"
      field_value = $input.event_id
      data = `$input|pick:($raw_input|keys)`|filter_null|filter_empty_text
    } as $event
  }

  response = $event
}