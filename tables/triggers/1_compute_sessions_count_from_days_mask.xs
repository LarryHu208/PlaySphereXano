// Automatically derives sessions_count by counting set bits in days_mask on insert and update.
// 
table_trigger "Compute sessions_count from days_mask" {
  table = "player_schedule_entry"

  input {
    json new
    json old
    enum action {
      values = ["insert", "update", "delete", "truncate"]
    }
  
    text datasource
  }

  stack {
  }

  actions = {insert: true, update: true}
  datasources = ["live"]
  tags = ["derived-field"]
}