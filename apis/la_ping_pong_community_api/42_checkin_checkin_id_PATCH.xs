// Edit checkin record
query "checkin/{checkin_id}" verb=PATCH {
  api_group = "LA Ping Pong Community API"

  input {
    int checkin_id? filters=min:1
    dblink {
      table = "checkin"
    }
  }

  stack {
    util.get_raw_input {
      encoding = "json"
      exclude_middleware = false
    } as $raw_input
  
    db.patch checkin {
      field_name = "id"
      field_value = $input.checkin_id
      data = `$input|pick:($raw_input|keys)`|filter_null|filter_empty_text
    } as $checkin
  }

  response = $checkin
}