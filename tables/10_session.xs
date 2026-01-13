table session {
  auth = false

  schema {
    int id
    timestamp created_at?=now
    int club_id? {
      table = "club"
    }
  
    date date?
    text start_time?
    text end_time?
    text recurrence_note?
    text crowd_level?
    int level_min?
    int level_max?
    text level_range_label?
    text vibe_tags?
    text description?
    bool is_published?
    bool is_recurring?
    int rsvp_count?
    timestamp updated_at?
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
  ]
}