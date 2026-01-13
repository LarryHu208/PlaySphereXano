// Creates a new player profile and optionally initializes their playing schedule within the LA Ping Pong Community API.
// Robust additions: accept club PK or public club id (14..24), normalize empty enums, treat 0 as null.
query add_player_with_schedule verb=POST {
  api_group = "LA Ping Pong Community API"

  input {
    text name filters=trim
    int rating?
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
  
    enum bio? {
      values = [
        "Social"
        "Training"
        "Practicing"
        "Play Matches"
        "Competing"
        "Doubles"
      ]
    }
  
    text style? filters=trim
  
    // PK-style club references (existing)
    int home_club_id? {
      table = "club"
    }
  
    bool create_schedule?=true
    int default_club_id? {
      table = "club"
    }
  
    int club_id? {
      table = "club"
    }
  
    // Public-id style club references (NEW)
    int home_club_public_id?
  
    int default_club_public_id?
    int club_public_id?
    int days_mask?
    text start_time? filters=trim
    text end_time? filters=trim
    text notes? filters=trim
    int confidence?=3
  }

  stack {
    // ----------------------------
    // 0) Defaults (local vars only)
    // ----------------------------
    var $create_schedule {
      value = $input.create_schedule
    }
  
    conditional {
      if ($create_schedule == null) {
        var.update $create_schedule {
          value = true
        }
      }
    }
  
    var $confidence {
      value = $input.confidence
    }
  
    conditional {
      if (($confidence == null) || ($confidence < 1) || ($confidence > 5)) {
        var.update $confidence {
          value = 3
        }
      }
    }
  
    var $end_time_final {
      value = $input.end_time
    }
  
    conditional {
      if (($end_time_final == null) || (($end_time_final|trim) == "")) {
        var.update $end_time_final {
          value = "11PM"
        }
      }
    }
  
    // ----------------------------
    // 0.5) Normalize: treat 0 as null for PK club ids + empty enums to null
    // ----------------------------
    var $club_id_in {
      value = $input.club_id
    }
  
    var $home_club_id_in {
      value = $input.home_club_id
    }
  
    var $default_club_id_in {
      value = $input.default_club_id
    }
  
    conditional {
      if ($club_id_in == 0) {
        var.update $club_id_in {
          value = null
        }
      }
    }
  
    conditional {
      if ($home_club_id_in == 0) {
        var.update $home_club_id_in {
          value = null
        }
      }
    }
  
    conditional {
      if ($default_club_id_in == 0) {
        var.update $default_club_id_in {
          value = null
        }
      }
    }
  
    var $level_tag_in {
      value = $input.level_tag
    }
  
    var $bio_in {
      value = $input.bio
    }
  
    conditional {
      if (($level_tag_in != null) && (($level_tag_in|to_text|trim) == "")) {
        var.update $level_tag_in {
          value = null
        }
      }
    }
  
    conditional {
      if (($bio_in != null) && (($bio_in|to_text|trim) == "")) {
        var.update $bio_in {
          value = null
        }
      }
    }
  
    // ----------------------------
    // 1) Required: name
    // ----------------------------
    precondition ((($input.name|strlen) > 0)) {
      error_type = "inputerror"
      error = "Player name is required."
    }
  
    // ----------------------------
    // 2) MVP validation when create_schedule=true
    // ----------------------------
    conditional {
      if ($create_schedule) {
        precondition ((($input.days_mask != null) && ($input.days_mask >= 1) && ($input.days_mask <= 127))) {
          error_type = "inputerror"
          error = "days_mask is required (1..127) when create_schedule=true."
        }
      
        // accept PK or public id for club selection
        precondition ((($club_id_in != null) || ($default_club_id_in != null) || ($input.club_public_id != null) || ($input.default_club_public_id != null))) {
          error_type = "inputerror"
          error = "Provide club_id/default_club_id (PK) or club_public_id/default_club_public_id (14..24) when create_schedule=true."
        }
      
        precondition ((($input.start_time != null) && (($input.start_time|trim) != ""))) {
          error_type = "inputerror"
          error = "start_time is required when create_schedule=true."
        }
      
        var $st_chk {
          value = $input.start_time
            |to_text
            |trim
            |to_upper
            |replace:" ":""
        }
      
        precondition ((($st_chk|contains:"AM") || ($st_chk|contains:"PM") || ($st_chk|contains:":"))) {
          error_type = "inputerror"
          error = "start_time must look like a time (e.g. 5PM, 5:30PM, 17:00)."
        }
      
        conditional {
          if (($input.end_time != null) && (($input.end_time|trim) != "")) {
            var $et_chk {
              value = $input.end_time
                |to_text
                |trim
                |to_upper
                |replace:" ":""
            }
          
            precondition ((($et_chk|contains:"AM") || ($et_chk|contains:"PM") || ($et_chk|contains:":"))) {
              error_type = "inputerror"
              error = "end_time must look like a time (e.g. 9PM, 9:15PM, 21:00)."
            }
          }
        }
      }
    }
  
    // ----------------------------
    // 2.5) Check for duplicate players (case-insensitive)
    // ----------------------------
    var $name_norm {
      value = $input.name
        |to_text
        |trim
        |to_lower
    }
  
    db.query player {
      where = 1 == 1
      return = {type: "list"}
    } as $all_players
  
    foreach ($all_players) {
      each as $p {
        var $p_norm {
          value = $p.display_name
            |to_text
            |trim
            |to_lower
        }
      
        conditional {
          if ($p_norm == $name_norm) {
            throw {
              name = "inputerror"
              value = "A player with this name already exists."
            }
          }
        }
      }
    }
  
    // ----------------------------
    // 3) Resolve club PKs (PK or public id)
    // IMPORTANT: In EACH db.query club step below, set WHERE in the UI:
    //   public_club_id = $input.<corresponding_public_id>
    // ----------------------------
  
    // Home club pk
    var $home_club_pk {
      value = $home_club_id_in
    }
  
    conditional {
      if (($home_club_pk == null) && ($input.home_club_public_id != null)) {
        db.query club {
          return = {type: "single"}
        } as $home_club_row
      
        conditional {
          if ($home_club_row == null) {
            throw {
              name = "inputerror"
              value = "home_club_public_id did not match any club."
            }
          }
        }
      
        var.update $home_club_pk {
          value = $home_club_row.id
        }
      }
    }
  
    // Default club pk
    var $default_club_pk {
      value = $default_club_id_in
    }
  
    conditional {
      if (($default_club_pk == null) && ($input.default_club_public_id != null)) {
        db.query club {
          return = {type: "single"}
        } as $default_club_row
      
        conditional {
          if ($default_club_row == null) {
            throw {
              name = "inputerror"
              value = "default_club_public_id did not match any club."
            }
          }
        }
      
        var.update $default_club_pk {
          value = $default_club_row.id
        }
      }
    }
  
    // Entry club pk
    var $club_pk {
      value = $club_id_in
    }
  
    conditional {
      if (($club_pk == null) && ($input.club_public_id != null)) {
        db.query club {
          return = {type: "single"}
        } as $club_row
      
        conditional {
          if ($club_row == null) {
            throw {
              name = "inputerror"
              value = "club_public_id did not match any club."
            }
          }
        }
      
        var.update $club_pk {
          value = $club_row.id
        }
      }
    }
  
    // If creating schedule, fallback entry club to default club
    conditional {
      if ($create_schedule) {
        conditional {
          if ($club_pk == null) {
            var.update $club_pk {
              value = $default_club_pk
            }
          }
        }
      
        precondition (($club_pk != null)) {
          error_type = "inputerror"
          error = "Could not resolve club for schedule entry. Provide club_id/club_public_id or default_club_id/default_club_public_id."
        }
      }
    }
  
    // ----------------------------
    // 4) Create player (use resolved pk)
    // ----------------------------
    db.add player {
      data = {
        display_name: $input.name
        rating      : $input.rating
        level_tag   : $level_tag_in
        bio         : $bio_in
        style       : $input.style
        home_club_id: $home_club_pk
        source      : "manual"
        is_active   : true
      }
    } as $player
  
    // early return if no schedule
    conditional {
      if ($create_schedule == false) {
        return {
          value = {player: $player}
        }
      }
    }
  
    // ----------------------------
    // 5) Create schedule + entry
    // ----------------------------
    db.add player_schedule {
      data = {
        player_id      : $player.id
        default_club_id: $default_club_pk
        timezone       : "America/Los_Angeles"
        active         : true
      }
    } as $schedule
  
    db.add player_schedule_entry {
      data = {
        schedule_id: $schedule.id
        days_mask  : $input.days_mask
        start_time : $input.start_time
        end_time   : $end_time_final
        club_id    : $club_pk
        notes      : $input.notes
        confidence : $confidence
      }
    } as $entry
  
    var $result {
      value = {player: $player, schedule: $schedule, entry: $entry}
    }
  }

  response = $result
  tags = ["player"]
}