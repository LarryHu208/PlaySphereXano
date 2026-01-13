table rsvp {
  auth = false

  schema {
    int id
    timestamp created_at?=now
    int session_id? {
      table = "session"
    }
  
    int user_id? {
      table = "user"
    }
  
    text player_name?
    int player_rating?
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
  ]
}