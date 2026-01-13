// Stores individual entries for a user's playing schedule.
table user_schedule_entry {
  auth = false

  schema {
    int id
    timestamp created_at?=now
  
    // Reference to the parent user schedule.
    int schedule_id? {
      table = "user_schedule"
    }
  
    // Day of the week (0=Sunday to 6=Saturday).
    int day_of_week?
  
    // Start time for the schedule entry.
    text start_time? filters=trim
  
    // End time for the schedule entry.
    text end_time? filters=trim
  
    // Optional club for this specific schedule entry.
    int club_id? {
      table = "club"
    }
  
    // Notes for the schedule entry.
    text notes? filters=trim
  
    // Confidence level for this schedule entry.
    int confidence?
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "gin", field: [{name: "xdo", op: "jsonb_path_op"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
  ]
}