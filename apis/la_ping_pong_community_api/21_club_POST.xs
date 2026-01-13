// Add club record
query club verb=POST {
  api_group = "LA Ping Pong Community API"

  input {
    dblink {
      table = "club"
    }
  }

  stack {
    db.add club {
      data = {created_at: "now"}
    } as $club
  }

  response = $club
}