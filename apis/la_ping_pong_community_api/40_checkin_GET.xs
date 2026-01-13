// Query all checkin records
query checkin verb=GET {
  api_group = "LA Ping Pong Community API"

  input {
  }

  stack {
    db.query checkin {
      return = {type: "list"}
    } as $checkin
  }

  response = $checkin
}