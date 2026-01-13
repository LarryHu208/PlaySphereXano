// Get rsvp record
query "rsvp/{rsvp_id}" verb=GET {
  api_group = "LA Ping Pong Community API"

  input {
    int rsvp_id? filters=min:1
  }

  stack {
    db.get rsvp {
      field_name = "id"
      field_value = $input.rsvp_id
    } as $rsvp
  
    precondition ($rsvp != null) {
      error_type = "notfound"
      error = "Not Found."
    }
  }

  response = $rsvp
}