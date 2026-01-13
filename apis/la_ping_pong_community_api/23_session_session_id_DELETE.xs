// Delete session record.
query "session/{session_id}" verb=DELETE {
  api_group = "LA Ping Pong Community API"

  input {
    int session_id? filters=min:1
  }

  stack {
    db.del session {
      field_name = "id"
      field_value = $input.session_id
    }
  }

  response = null
}