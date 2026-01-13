// Add event record
query event verb=POST {
  api_group = "LA Ping Pong Community API"

  input {
    dblink {
      table = "event"
    }
  }

  stack {
    db.add event {
      data = {created_at: "now"}
    } as $event
  }

  response = $event
}