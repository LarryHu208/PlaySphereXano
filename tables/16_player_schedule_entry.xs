// Stores individual entries detailing a player's typical playing times.
table player_schedule_entry {
  auth = false

  schema {
    int id
    timestamp created_at?=now
  
    // Reference to the parent player schedule, required.
    int schedule_id? {
      table = "player_schedule"
    }
  
    // Day of the week (0=Sunday to 6=Saturday), required.
    int days_mask?
  
    // Start time for the schedule entry (e.g., '7:00 PM'), required.
    text start_time? filters=trim
  
    // End time for the schedule entry (e.g., '10:00 PM'), required.
    text end_time? filters=trim
  
    // Optional club for this specific schedule entry; if null, use default_club_id from player_schedule.
    int club_id? {
      table = "club"
    }
  
    // Optional notes for the schedule entry.
    text notes? filters=trim
  
    // Confidence level for this schedule entry (default: 2).
    int confidence?=3
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "gin", field: [{name: "xdo", op: "jsonb_path_op"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
    {type: "btree", field: [{name: "club_id", op: "asc"}]}
  ]
}