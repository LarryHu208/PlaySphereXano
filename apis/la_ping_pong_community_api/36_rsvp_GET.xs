// Query all rsvp records
query rsvp verb=GET {
  api_group = "LA Ping Pong Community API"

  input {
  }

  stack {
    db.query rsvp {
      return = {type: "list"}
    } as $rsvp
  }

  response = $rsvp
}