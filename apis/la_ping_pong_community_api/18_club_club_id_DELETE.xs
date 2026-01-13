// Delete club record.
query "club/{club_id}" verb=DELETE {
  api_group = "LA Ping Pong Community API"

  input {
    int club_id? filters=min:1
  }

  stack {
    db.del club {
      field_name = "id"
      field_value = $input.club_id
    }
  }

  response = null
}