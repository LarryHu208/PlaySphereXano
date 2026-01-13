// Get club record
query "club/{club_id}" verb=GET {
  api_group = "LA Ping Pong Community API"

  input {
    int club_id? filters=min:1
  }

  stack {
    db.get club {
      field_name = "id"
      field_value = $input.club_id
    } as $club
  
    precondition ($club != null) {
      error_type = "notfound"
      error = "Not Found."
    }
  }

  response = $club
}