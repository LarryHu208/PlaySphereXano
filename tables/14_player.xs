// Stores information about static regular players for activity tracking.
table player {
  auth = false

  schema {
    int id
    timestamp created_at?=now
  
    // The player's display name, required.
    text display_name? filters=trim
  
    // id corresponding with club played at most
    int? home_club_id?
  
    // The player's rating, required.
    int rating?
  
    // Player skill level from a predefined list.
    enum level_tag? {
      values = [
        "Beginner"
        "Beg-Int"
        "Intermediate"
        "Int-Adv"
        "Advanced"
        "Pro"
      ]
    
    }
  
    // Optional short biography of the player.
    enum bio?="Play Matches" {
      values = [
        "Social"
        "Training"
        "Practicing"
        "Play Matches"
        "Competing"
        "Doubles"
      ]
    
    }
  
    // Optional description of the player's playing style.
    text style?="Right Hand, Standard" filters=trim
  
    // Source of the player's information (e.g., 'Discord LATTA').
    text source?=Discord filters=trim
  
    // Indicates if the player is active (default: true).
    bool is_active?=true
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "gin", field: [{name: "xdo", op: "jsonb_path_op"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
  ]
}