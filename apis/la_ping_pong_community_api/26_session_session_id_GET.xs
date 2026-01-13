// Get session record
query "session/{session_id}" verb=GET {
  api_group = "LA Ping Pong Community API"

  input {
    int session_id? filters=min:1
  }

  stack {
    db.get session {
      field_name = "id"
      field_value = $input.session_id
    } as $session
  
    precondition ($session != null) {
      error_type = "notfound"
      error = "Not Found."
    }
  }

  response = $session
}