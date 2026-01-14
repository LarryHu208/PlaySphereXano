// Creates a new check-in OR extends an existing active one (upsert). Handles player snapshots vs guest input normalization.
query checkin verb=POST {
  api_group = "LA Ping Pong Community API"

  input {
    // ID of the club to check in to
    int club_id {
      table = "club"
    }
  
    // ID of the registered player (optional)
    int player_id? {
      table = "player"
    }
  
    // Display name for the check-in (required if player_id is null)
    text display_name? filters=trim
  
    // Guest rating (ignored if player_id is present)
    int rating?
  
    // Guest level tag (ignored if player_id is present)
    enum level_tag? {
      values = [
        "Beginner"
        "Beg-Int"
        "Intermediate"
        "Int-Adv"
        "Advanced"
        "Pro"
      ]
    
    }
  
    // Duration of the check-in in minutes
    int duration_minutes?=120 filters=min:1
  
    // Source of the check-in
    enum source?=web {
      values = ["web", "qr", "discord", "manual"]
    }
  
    // Optional notes
    text notes? filters=trim
  }

  stack {
    // ---- Normalize Inputs ----
    // Normalize inputs and validate requirements
    group {
      stack {
        var $clean_display_name {
          value = $input.display_name
        }
      
        // Clamp duration between 30 and 240 minutes
        var $duration {
          value = ($input.duration_minutes < 30 ? 30 : ($input.duration_minutes > 240 ? 240 : $input.duration_minutes))
        }
      
        precondition ($input.club_id > 0) {
          error_type = "inputerror"
          error = "Invalid Club ID provided."
        }
      
        precondition ($input.player_id != null || ($clean_display_name|strlen) > 0) {
          error_type = "inputerror"
          error = "Either Player ID or Display Name is required."
        }
      }
    }
  
    // ---- Compute Expiration ----
    var $current_time {
      value = now
    }
  
    var $expires_at {
      value = $current_time
        |add_secs_to_timestamp:$duration * 60
    }
  
    // ---- Prepare Data Snapshots ----
    var $snapshot_display_name {
      value = $clean_display_name
    }
  
    var $snapshot_rating {
      value = null
    }
  
    var $snapshot_level_tag {
      value = null
    }
  
    conditional {
      // Path 1: Player Selected (Snapshot from DB)
      if ($input.player_id != null) {
        db.get player {
          field_name = "id"
          field_value = $input.player_id
        } as $player_data
      
        precondition ($player_data != null) {
          error_type = "inputerror"
          error = "Player ID not found."
        }
      
        var.update $snapshot_display_name {
          value = $player_data.display_name
        }
      
        var.update $snapshot_rating {
          value = $player_data.rating
        }
      
        var.update $snapshot_level_tag {
          value = $player_data.level_tag
        }
      }
    
      // Path 2: Guest (Normalize Inputs)
      else {
        var.update $snapshot_rating {
          value = $input.rating
        }
      
        var.update $snapshot_level_tag {
          value = $input.level_tag
        }
      
        // Derive Level Tag from Rating if missing
        conditional {
          if ($snapshot_rating != null && $snapshot_level_tag == null) {
            conditional {
              if ($snapshot_rating < 1000) {
                var.update $snapshot_level_tag {
                  value = "Beginner"
                }
              }
            
              elseif ($snapshot_rating < 1400) {
                var.update $snapshot_level_tag {
                  value = "Beg-Int"
                }
              }
            
              elseif ($snapshot_rating < 1900) {
                var.update $snapshot_level_tag {
                  value = "Intermediate"
                }
              }
            
              elseif ($snapshot_rating < 2200) {
                var.update $snapshot_level_tag {
                  value = "Int-Adv"
                }
              }
            
              else {
                var.update $snapshot_level_tag {
                  value = "Advanced"
                }
              }
            }
          }
        }
      
        // Derive Rating from Level Tag if missing
        conditional {
          if ($snapshot_level_tag != null && $snapshot_rating == null) {
            conditional {
              if ($snapshot_level_tag == "Beginner") {
                var.update $snapshot_rating {
                  value = 500
                }
              }
            
              elseif ($snapshot_level_tag == "Beg-Int") {
                var.update $snapshot_rating {
                  value = 1200
                }
              }
            
              elseif ($snapshot_level_tag == "Intermediate") {
                var.update $snapshot_rating {
                  value = 1500
                }
              }
            
              elseif ($snapshot_level_tag == "Int-Adv") {
                var.update $snapshot_rating {
                  value = 2000
                }
              }
            
              elseif ($snapshot_level_tag == "Advanced") {
                var.update $snapshot_rating {
                  value = 2200
                }
              }
            
              elseif ($snapshot_level_tag == "Pro") {
                var.update $snapshot_rating {
                  value = 2500
                }
              }
            }
          }
        }
      }
    }
  
    // ---- UPSERT: Find Existing Active Check-in ----
    conditional {
      if ($input.player_id != null) {
        db.query checkin {
          where = $db.checkin.player_id == $input.player_id && $db.checkin.club_id == $input.club_id && $db.checkin.expires_at > $current_time
          sort = {expires_at: "desc"}
          return = {type: "single"}
        } as $existing_checkin
      }
    
      else {
        db.query checkin {
          where = $db.checkin.display_name == $snapshot_display_name && $db.checkin.club_id == $input.club_id && $db.checkin.expires_at > $current_time
          sort = {expires_at: "desc"}
          return = {type: "single"}
        } as $existing_checkin
      }
    }
  
    // ---- Update or Insert ----
    conditional {
      if ($existing_checkin) {
        db.edit checkin {
          field_name = "id"
          field_value = $existing_checkin.id
          data = {
            expires_at  : $expires_at
            notes       : $input.notes
            rating      : $snapshot_rating
            level_tag   : $snapshot_level_tag
            display_name: $snapshot_display_name
            source      : $input.source
          }
        } as $checkin
      }
    
      else {
        db.add checkin {
          data = {
            club_id     : $input.club_id
            player_id   : $input.player_id
            display_name: $snapshot_display_name
            rating      : $snapshot_rating
            level_tag   : $snapshot_level_tag
            expires_at  : $expires_at
            source      : $input.source
            notes       : $input.notes
          }
        } as $checkin
      }
    }
  }

  response = {
    checkin_id  : $checkin.id
    club_id     : $checkin.club_id
    player_id   : $checkin.player_id
    display_name: $checkin.display_name
    rating      : $checkin.rating
    level_tag   : $checkin.level_tag
    expires_at  : $checkin.expires_at
    source      : $checkin.source
    notes       : $checkin.notes
  }
}