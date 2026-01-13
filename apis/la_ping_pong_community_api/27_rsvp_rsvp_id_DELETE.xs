// Delete rsvp record.
query "rsvp/{rsvp_id}" verb=DELETE {
  api_group = "LA Ping Pong Community API"

  input {
    int rsvp_id? filters=min:1
  }

  stack {
    db.del rsvp {
      field_name = "id"
      field_value = $input.rsvp_id
    }
  }

  response = null
}