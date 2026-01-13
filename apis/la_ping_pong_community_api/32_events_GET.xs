// Retrieve a list of upcoming, published events sorted by date.
query events verb=GET {
  api_group = "LA Ping Pong Community API"

  input {
  }

  stack {
    db.query event {
      where = $db.event.date >= now && $db.event.is_published
      sort = {event.date: "asc"}
      return = {type: "list"}
    } as $events
  }

  response = $events
}