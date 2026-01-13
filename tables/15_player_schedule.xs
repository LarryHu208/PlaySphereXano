// Stores the typical playing schedule preferences for static players.
table player_schedule {
  auth = false

  schema {
    int id
    timestamp created_at?=now
  
    // Reference to the player this schedule belongs to, required.
    int player_id? {
      table = "player"
    }
  
    // Optional default club for this player's schedule entries.
    int default_club_id? {
      table = "club"
    }
  
    // Timezone for the player's schedule (default: "America/Los_Angeles").
    text timezone?=PST filters=trim
  
    // Indicates if the player schedule is active (default: true).
    bool active?=true
  
    // Timestamp of the last update to the schedule.
    timestamp updated_at?
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "gin", field: [{name: "xdo", op: "jsonb_path_op"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
    {
      type : "btree|unique"
      field: [{name: "player_id", op: "asc"}]
    }
  ]
}