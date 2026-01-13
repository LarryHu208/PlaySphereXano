// Add checkin record
query checkin verb=POST {
  api_group = "LA Ping Pong Community API"

  input {
    dblink {
      table = "checkin"
    }
  }

  stack {
    db.add checkin {
      data = {created_at: "now"}
    } as $checkin
  }

  response = $checkin
}