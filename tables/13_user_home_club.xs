// Manages the many-to-many relationship between users and their home clubs.
table user_home_club {
  auth = false

  schema {
    int id
    timestamp created_at?=now
  
    // Reference to the user.
    int user_id? {
      table = "user"
    }
  
    // Reference to the club.
    int club_id? {
      table = "club"
    }
  }

  index = [
    {type: "primary", field: [{name: "id"}]}
    {type: "gin", field: [{name: "xdo", op: "jsonb_path_op"}]}
    {type: "btree", field: [{name: "created_at", op: "desc"}]}
    {
      type : "btree|unique"
      field: [{name: "user_id", op: "asc"}, {name: "club_id", op: "asc"}]
    }
  ]
}