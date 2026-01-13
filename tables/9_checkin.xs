table checkin {
  auth = false

  schema {
    int id
    timestamp created_at?=now
    int player_id? {
      table = "user"
    }
  
    int club_id? {
      table = "club"
    }
  
    date date?
    text start_time?
    text end_time?
    text status?
    text note?
    int rating?
    text level_tag?
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
  ]
}