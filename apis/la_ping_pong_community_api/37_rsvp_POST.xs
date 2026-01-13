// Add rsvp record
query rsvp verb=POST {
  api_group = "LA Ping Pong Community API"

  input {
    dblink {
      table = "rsvp"
    }
  }

  stack {
    db.add rsvp {
      data = {created_at: "now"}
    } as $rsvp
  }

  response = $rsvp
}