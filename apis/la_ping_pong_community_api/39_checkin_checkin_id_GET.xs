// Get checkin record
query "checkin/{checkin_id}" verb=GET {
  api_group = "LA Ping Pong Community API"

  input {
    int checkin_id? filters=min:1
  }

  stack {
    db.get checkin {
      field_name = "id"
      field_value = $input.checkin_id
    } as $checkin
  
    precondition ($checkin != null) {
      error_type = "notfound"
      error = "Not Found."
    }
  }

  response = $checkin
}