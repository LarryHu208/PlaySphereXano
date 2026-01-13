// gets total number of sessions 
query "stats/session/count" verb=GET {
  api_group = "LA Ping Pong Community API"

  input {
  }

  stack {
    db.query player_schedule_entry {
      return = {type: "list"}
    } as $entries
  
    api.lambda {
      code = """
          let total = 0;
          // Iterate through all entries available in the function stack variable
          $var.entries.forEach(entry => {
            let mask = entry.days_mask || 0;
            // Count set bits in the mask to determine number of days/sessions
            while (mask > 0) {
              if (mask & 1) total++;
              mask >>= 1;
            }
          });
          return total;
        """
      timeout = 10
    } as $total_sessions
  }

  response = $total_sessions
}