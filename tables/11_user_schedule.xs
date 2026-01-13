// Stores default playing schedule preferences for users.
table user_schedule {
  auth = false

  schema {
    int id
    timestamp created_at?=now
  
    // Reference to the user this schedule belongs to.
    int user_id? {
      table = "user"
    }
  
    // Optional default club for the user's schedule entries.
    int default_club_id? {
      table = "club"
    }
  
    // Timezone for the user's schedule.
    text timezone? filters=trim
  
    // Indicates if the user schedule is active.
    bool active?
  
    // Timestamp of the last update to the schedule.
    timestamp updated_at?
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "gin", field: [{name: "xdo", op: "jsonb_path_op"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
    {type: "btree|unique", field: [{name: "user_id", op: "asc"}]}
  ]
}