table checkin {
  auth = false

  schema {
    int id
    timestamp created_at?=now
    int player_id? {
      table = "user"
    }
  
    // name of checkin player
    text display_name? filters=trim
  
    int club_id? {
      table = "club"
    }
  
    timestamp expires_at?
  
    // Rating of player
    int rating?
  
    // level tag of player
    enum? level_tag? {
      values = [
        "Beginner"
        "Beg-Int"
        "Intermediate"
        "Int-Adv"
        "Advanced"
        "Pro"
      ]
    
    }
  
    // any additional description
    text? notes? filters=trim
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
  ]
}