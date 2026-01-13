// Add session record
query session verb=POST {
  api_group = "LA Ping Pong Community API"

  input {
    dblink {
      table = "session"
    }
  }

  stack {
    db.add session {
      data = {created_at: "now"}
    } as $session
  }

  response = $session
}