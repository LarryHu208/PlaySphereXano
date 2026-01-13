// Edit session record
query "session/{session_id}" verb=PATCH {
  api_group = "LA Ping Pong Community API"

  input {
    int session_id? filters=min:1
    dblink {
      table = "session"
    }
  }

  stack {
    util.get_raw_input {
      encoding = "json"
      exclude_middleware = false
    } as $raw_input
  
    db.patch session {
      field_name = "id"
      field_value = $input.session_id
      data = `$input|pick:($raw_input|keys)`|filter_null|filter_empty_text
    } as $session
  }

  response = $session
}