// Edit rsvp record
query "rsvp/{rsvp_id}" verb=PATCH {
  api_group = "LA Ping Pong Community API"

  input {
    int rsvp_id? filters=min:1
    dblink {
      table = "rsvp"
    }
  }

  stack {
    util.get_raw_input {
      encoding = "json"
      exclude_middleware = false
    } as $raw_input
  
    db.patch rsvp {
      field_name = "id"
      field_value = $input.rsvp_id
      data = `$input|pick:($raw_input|keys)`|filter_null|filter_empty_text
    } as $rsvp
  }

  response = $rsvp
}