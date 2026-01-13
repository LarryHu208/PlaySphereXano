// Add session record
query increment_session_rsvp verb=POST {
  api_group = "LA Ping Pong Community API"

  input {
    // The ID of the session to RSVP to
    int session_id
  }

  stack {
    db.get session {
      field_name = "id"
      field_value = $input.session_id
    } as $session
  
    precondition ($session != null) {
      error_type = "not_found"
      error = "Session not found"
    }
  
    var $rsvp_count {
      value = $session.rsvp_count
    }
  
    conditional {
      if ($rsvp_count == null) {
        var.update $rsvp_count {
          value = 0
        }
      }
    }
  
    math.add $rsvp_count {
      value = 1
    }
  
    db.edit session {
      field_name = "id"
      field_value = $input.session_id
      data = {rsvp_count: $rsvp_count}
    } as $updated_session
  }

  response = {
    ok                : true
    session_id        : $updated_session.id
    updated_rsvp_count: $updated_session.rsvp_count
  }
}