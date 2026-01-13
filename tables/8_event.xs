table event {
  auth = false

  schema {
    int id
    timestamp created_at?=now
    text title?
    text description?
    enum event_type? {
      values = [
        "Social Play"
        "Tournament"
        "Special Event"
        "Other"
        "Weekly Round Robin"
      ]
    }
  
    date date?
    text start_time?
    text end_time?
  
    // Days of the week this event occurs on
    enum[] weekly_event? {
      values = [
        "Monday"
        "Tuesday"
        "Wednesday"
        "Thursday"
        "Friday"
        "Saturday"
        "Sunday"
      ]
    
    }
  
    int club_id? {
      table = "club"
    }
  
    text address?
    text cost?
    text organizer?
    text registration_link?
    text skill_level?
    bool is_featured?
    bool is_published?
    timestamp updated_at?
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
  ]
}