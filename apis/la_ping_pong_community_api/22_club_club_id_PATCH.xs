// Edit club record
query "club/{club_id}" verb=PATCH {
  api_group = "LA Ping Pong Community API"

  input {
    int club_id? filters=min:1
    dblink {
      table = "club"
    }
  }

  stack {
    util.get_raw_input {
      encoding = "json"
      exclude_middleware = false
    } as $raw_input
  
    db.patch club {
      field_name = "id"
      field_value = $input.club_id
      data = `$input|pick:($raw_input|keys)`|filter_null|filter_empty_text
    } as $club
  }

  response = $club
}