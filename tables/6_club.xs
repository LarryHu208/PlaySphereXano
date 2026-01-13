table club {
  auth = false

  schema {
    int id
    timestamp created_at?=now
    text name?
  
    // integer unique, public club id to identify club
    int public_club_id?
  
    text address?
    text city?
    text hours?
    int table_count?
    int typical_level_min?
    int typical_level_max?
  
    // Top Player level
    text Max_Rating? filters=trim
  
    text day_pass_cost?
    text peak_hours?
    text description?
    text equipment_notes?
  
    // Tournaments
    text Round_Robins? filters=trim
  
    text google_maps_url?
    text photo_url?
    bool is_active?=true
    timestamp updated_at?
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
  ]
}