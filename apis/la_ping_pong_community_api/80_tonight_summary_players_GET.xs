// Returns per-club player previews for the current window (full-day or tonight).
// Use this for: "click club -> show who's playing"
// Endpoint: GET /tonight_summary/players
query tonight_summary_players verb=GET {
  api_group = "LA Ping Pong Community API"

  input {
    enum mode? {
      values = ["full_day", "tonight"]
    }
  
    int window_start_minutes?
    int window_end_minutes?
    int per_club_limit?
  }

  stack {
    // default inputs:
    //  default mode
    conditional {
      if (($mode == null) || ($mode == "")) {
        var.update $mode {
          value = "full_day"
        }
      }
    }
  
    // default per_club_limit
    conditional {
      if (($per_club_limit == null) || ($per_club_limit < 1)) {
        var.update $per_club_limit {
          value = 50
        }
      }
    }
  
    // ----------------------------
    // 1) Time / Window Variables
    // ----------------------------
    var $timezone {
      value = "America/Los_Angeles"
    }
  
    var $now_la {
      value = "now"|to_timestamp:$timezone
    }
  
    var $today_weekday_raw {
      value = $now_la
        |format_timestamp:"w":$timezone
        |to_int
    }
  
    var $today_weekday {
      value = $today_weekday_raw
    }
  
    conditional {
      if ($today_weekday_raw == 7) {
        var.update $today_weekday {
          value = 0
        }
      }
    }
  
    // today_mask: Sunday=1, Monday=2, Tuesday=4, ...
    var $today_mask {
      value = 2|pow:$today_weekday|to_int
    }
  
    var $now_hour {
      value = $now_la
        |format_timestamp:"H":$timezone
        |to_int
    }
  
    var $now_minute {
      value = $now_la
        |format_timestamp:"i":$timezone
        |to_int
    }
  
    var $now_minutes {
      value = ($now_hour * 60) + $now_minute
    }
  
    // Window defaults
    var $today_start_minutes {
      value = 0
    }
  
    var $today_end_minutes {
      value = 1439
    }
  
    // If mode=tonight and no explicit window passed, set a reasonable default (6PM–11PM)
    conditional {
      if ($mode == "tonight") {
        var.update $today_start_minutes {
          value = 18 * 60
        }
      
        var.update $today_end_minutes {
          value = 23 * 60
        }
      }
    }
  
    // Allow explicit override
    conditional {
      if ($window_start_minutes != null) {
        var.update $today_start_minutes {
          value = $window_start_minutes
        }
      }
    }
  
    conditional {
      if ($window_end_minutes != null) {
        var.update $today_end_minutes {
          value = $window_end_minutes
        }
      }
    }
  
    var $is_full_day_window {
      value = ($today_start_minutes == 0) && ($today_end_minutes == 1439)
    }
  
    var $is_active_window {
      value = ($now_minutes >= $today_start_minutes) && ($now_minutes <= $today_end_minutes)
    }
  
    // ----------------------------
    // 2) Preload schedules + players
    // ----------------------------
    db.query player_schedule {
      where = 1 == 1
      return = {type: "list"}
    } as $schedules
  
    var $schedule_by_id {
      value = {}
    }
  
    foreach ($schedules) {
      each as $s {
        var $sid {
          value = $s.id|to_text
        }
      
        var.update $schedule_by_id {
          value = $schedule_by_id|set:$sid:$s
        }
      }
    }
  
    db.query player {
      where = 1 == 1
      return = {type: "list"}
    } as $players
  
    var $player_by_id {
      value = {}
    }
  
    foreach ($players) {
      each as $p {
        var $pid {
          value = $p.id|to_text
        }
      
        var.update $player_by_id {
          value = $player_by_id|set:$pid:$p
        }
      }
    }
  
    // ----------------------------
    // 3) Load clubs (for name + city)
    // ----------------------------
    db.query club {
      where = 1 == 1
      return = {type: "list"}
    } as $clubs
  
    var $club_by_id {
      value = {}
    }
  
    foreach ($clubs) {
      each as $c {
        // only active clubs
        conditional {
          if ($c.is_active != true) {
            continue
          }
        }
      
        var $cid {
          value = $c.id|to_text
        }
      
        var.update $club_by_id {
          value = $club_by_id|set:$cid:$c
        }
      }
    }
  
    // ----------------------------
    // 4) Entries -> per club player preview list
    // ----------------------------
    db.query player_schedule_entry {
      where = 1 == 1
      return = {type: "list"}
    } as $entries
  
    // club_id -> array of player preview objects
    var $players_by_club {
      value = {}
    }
  
    // For dedupe: club_id -> array of player_ids already added
    var $player_ids_by_club {
      value = {}
    }
  
    foreach ($entries) {
      each as $entry {
        // weekday match
        var $days_mask_int {
          value = $entry.days_mask|to_int
        }
      
        var $q {
          value = $days_mask_int / $today_mask
        }
      
        var $q_floor {
          value = $q
        }
      
        var.update $q_floor {
          value = $q_floor|floor
        }
      
        var $mask_on {
          value = $q_floor % 2
        }
      
        conditional {
          if ($mask_on != 1) {
            continue
          }
        }
      
        // schedule -> player
        var $schedule_id_key {
          value = $entry.schedule_id|to_text
        }
      
        conditional {
          if ($schedule_by_id|has:$schedule_id_key == false) {
            continue
          }
        }
      
        var $schedule {
          value = $schedule_by_id|get:$schedule_id_key
        }
      
        // IMPORTANT: adjust if your schedule field is different
        var $player_id_key {
          value = $schedule.player_id|to_text
        }
      
        conditional {
          if ($player_by_id|has:$player_id_key == false) {
            continue
          }
        }
      
        var $player {
          value = $player_by_id|get:$player_id_key
        }
      
        // effective club id
        var $eff_club_id {
          value = $entry.club_id
        }
      
        conditional {
          if ($eff_club_id == null) {
            var.update $eff_club_id {
              value = $schedule.default_club_id
            }
          }
        }
      
        conditional {
          if ($eff_club_id == null) {
            continue
          }
        }
      
        var $club_key {
          value = $eff_club_id|to_text
        }
      
        // If club is inactive / missing, skip
        conditional {
          if ($club_by_id|has:$club_key == false) {
            continue
          }
        }
      
        // ----------------------------
        // If NOT full-day, enforce time overlap
        // ----------------------------
        conditional {
          if ($is_full_day_window == false) {
            // parse start/end times (simple support: "5PM", "5:30PM", "17:00", etc.)
            var $st_txt {
              value = $entry.start_time|to_text|trim
            }
          
            var $et_txt {
              value = $entry.end_time|to_text|trim
            }
          
            conditional {
              if (($st_txt == null) || ($st_txt == "")) {
                continue
              }
            }
          
            conditional {
              if (($et_txt == null) || ($et_txt == "")) {
                var.update $et_txt {
                  value = "11PM"
                }
              }
            }
          
            var $st_raw {
              value = $st_txt
                |to_upper
                |replace:" ":""
                |replace:"–":"-"
                |replace:"—":"-"
            }
          
            var $et_raw {
              value = $et_txt
                |to_upper
                |replace:" ":""
                |replace:"–":"-"
                |replace:"—":"-"
            }
          
            // allow "5PM-9PM" in start_time if end_time missing
            conditional {
              if (($et_raw == null) || ($et_raw == "")) {
                conditional {
                  if ($st_raw|contains:"-") {
                    var $range_parts {
                      value = $st_raw|split:"-"
                    }
                  
                    var.update $st_raw {
                      value = $range_parts[0]
                    }
                  
                    var.update $et_raw {
                      value = $range_parts[1]
                    }
                  }
                }
              }
            }
          
            // whitelist: skip junk strings
            conditional {
              if (($st_raw|contains:"AM" == false) && ($st_raw|contains:"PM" == false) && ($st_raw|contains:":" == false)) {
                continue
              }
            }
          
            var $st_has_am {
              value = $st_raw|contains:"AM"
            }
          
            var $st_has_pm {
              value = $st_raw|contains:"PM"
            }
          
            var $et_has_am {
              value = $et_raw|contains:"AM"
            }
          
            var $et_has_pm {
              value = $et_raw|contains:"PM"
            }
          
            var $st_clean {
              value = $st_raw|replace:"AM":""|replace:"PM":""
            }
          
            var $et_clean {
              value = $et_raw|replace:"AM":""|replace:"PM":""
            }
          
            var $st_parts {
              value = $st_clean|split:":"
            }
          
            var $et_parts {
              value = $et_clean|split:":"
            }
          
            var $st_hour_str {
              value = $st_parts[0]
            }
          
            var $et_hour_str {
              value = $et_parts[0]
            }
          
            var $st_min_str {
              value = "00"
            }
          
            var $et_min_str {
              value = "00"
            }
          
            conditional {
              if (($st_parts|count) > 1) {
                var.update $st_min_str {
                  value = $st_parts[1]|slice:0:2
                }
              }
            }
          
            conditional {
              if (($et_parts|count) > 1) {
                var.update $et_min_str {
                  value = $et_parts[1]|slice:0:2
                }
              }
            }
          
            var $st_hour {
              value = $st_hour_str|to_int
            }
          
            var $et_hour {
              value = $et_hour_str|to_int
            }
          
            var $st_min {
              value = $st_min_str|to_int
            }
          
            var $et_min {
              value = $et_min_str|to_int
            }
          
            conditional {
              if (($st_hour == null) || ($et_hour == null) || ($st_min == null) || ($et_min == null)) {
                continue
              }
            }
          
            conditional {
              if ($st_has_pm && ($st_hour < 12)) {
                var.update $st_hour {
                  value = $st_hour + 12
                }
              }
            }
          
            conditional {
              if ($st_has_am && ($st_hour == 12)) {
                var.update $st_hour {
                  value = 0
                }
              }
            }
          
            conditional {
              if ($et_has_pm && ($et_hour < 12)) {
                var.update $et_hour {
                  value = $et_hour + 12
                }
              }
            }
          
            conditional {
              if ($et_has_am && ($et_hour == 12)) {
                var.update $et_hour {
                  value = 0
                }
              }
            }
          
            var $start_min {
              value = ($st_hour * 60) + $st_min
            }
          
            var $end_min {
              value = ($et_hour * 60) + $et_min
            }
          
            // overlap required
            conditional {
              if (($start_min > $today_end_minutes) || ($end_min < $today_start_minutes)) {
                continue
              }
            }
          }
        }
      
        // ----------------------------
        // Deduplicate per club
        // ----------------------------
        var $player_id_txt {
          value = $player.id|to_text
        }
      
        var $seen_ids {
          value = []
        }
      
        conditional {
          if ($player_ids_by_club|has:$club_key) {
            var.update $seen_ids {
              value = $player_ids_by_club|get:$club_key
            }
          }
        }
      
        conditional {
          if ($seen_ids|contains:$player_id_txt) {
            continue
          }
        }
      
        // enforce per_club_limit
        var $cur_list {
          value = []
        }
      
        conditional {
          if ($players_by_club|has:$club_key) {
            var.update $cur_list {
              value = $players_by_club|get:$club_key
            }
          }
        }
      
        conditional {
          if (($cur_list|count) >= $per_club_limit) {
            continue
          }
        }
      
        // add preview object
        var $club {
          value = $club_by_id|get:$club_key
        }
      
        array.push $cur_list {
          value = {
            player_id : $player.id
            name      : $player.name
            rating    : $player.rating
            level_tag : $player.level_tag
            club_id   : $club.id
            club_name : $club.name
            club_city : $club.city
            source    : "schedule"
            confidence: $entry.confidence
          }
        }
      
        array.push $seen_ids {
          value = $player_id_txt
        }
      
        var.update $players_by_club {
          value = $players_by_club|set:$club_key:$cur_list
        }
      
        var.update $player_ids_by_club {
          value = $player_ids_by_club|set:$club_key:$seen_ids
        }
      }
    }
  
    // ----------------------------
    // 5) Build response: array of clubs with players
    // ----------------------------
    var $result {
      value = []
    }
  
    foreach ($club_by_id) {
      each as $kv {
        // kv is a map entry; in Xano foreach(map) each becomes value, not key.
        // So we rebuild by iterating over $clubs instead (safe).
      }
    }
  
    // Safer: loop original clubs list (filtered by is_active earlier in map)
    foreach ($clubs) {
      each as $c {
        conditional {
          if ($c.is_active != true) {
            continue
          }
        }
      
        var $ck {
          value = $c.id|to_text
        }
      
        var $plist {
          value = []
        }
      
        conditional {
          if ($players_by_club|has:$ck) {
            var.update $plist {
              value = $players_by_club|get:$ck
            }
          }
        }
      
        array.push $result {
          value = {
            club_id             : $c.id
            club_name           : $c.name
            city                : $c.city
            window_start_minutes: $today_start_minutes
            window_end_minutes  : $today_end_minutes
            timezone            : $timezone
            is_active_window    : $is_active_window
            mode                : $mode
            players             : $plist
            player_count        : $plist|count
          }
        }
      }
    }
  
    // Sort by player_count desc
    var $sorted_result {
      value = $result|sort:"player_count"|reverse
    }
  }

  response = $sorted_result
}