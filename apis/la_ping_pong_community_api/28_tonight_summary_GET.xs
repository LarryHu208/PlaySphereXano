// Retrieves a list of ping pong sessions scheduled for today, including club details.
query tonight_summary verb=GET {
  api_group = "LA Ping Pong Community API"

  input {
  }

  stack {
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
  
    // Normalize weekday to 0..6 (Sunday=0)
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
  
    // Full-day window (you can later change this to "tonight")
    var $today_start_minutes {
      value = 0
    }
  
    var $today_end_minutes {
      value = 1439
    }
  
    var $is_full_day_window {
      value = ($today_start_minutes == 0) && ($today_end_minutes == 1439)
    }
  
    var $is_active_window {
      value = ($now_minutes >= $today_start_minutes) && ($now_minutes <= $today_end_minutes)
    }
  
    // ----------------------------
    // A) Preload schedules + players into maps
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
    // B) Expected players from schedule entries
    // ----------------------------
    db.query player_schedule_entry {
      where = 1 == 1
      return = {type: "list"}
    } as $entries
  
    var $expected_player_ids_by_club {
      value = {}
    }
  
    var $expected_count_by_club {
      value = {}
    }
  
    var $expected_min_rating_by_club {
      value = {}
    }
  
    var $expected_max_rating_by_club {
      value = {}
    }
  
    // Debug counters
    var $dbg_entries_count {
      value = $entries|count
    }
  
    var $dbg_mask_pass {
      value = 0
    }
  
    var $dbg_schedule_found {
      value = 0
    }
  
    var $dbg_player_found {
      value = 0
    }
  
    var $dbg_eligible_entries_today {
      value = 0
    }
  
    var $dbg_added {
      value = 0
    }
  
    var $dbg_first_bad_entry {
      value = null
    }
  
    var $dbg_first_bad_times {
      value = null
    }
  
    var $dbg_first_bad_parsed {
      value = null
    }
  
    var $dbg_first_bad_overlap_check {
      value = null
    }
  
    var $dbg_missing_start_time {
      value = 0
    }
  
    var $dbg_first_missing_time_entry {
      value = null
    }
  
    // IMPORTANT: parse_fail is now scoped to TODAY entries only
    var $dbg_parse_fail {
      value = 0
    }
  
    var $dbg_first_parse_fail {
      value = null
    }
  
    var $dbg_first_entry_raw {
      value = null
    }
  
    // Helper: add player -> club expected maps (duplicated inline because Xano has no funcs)
    foreach ($entries) {
      each as $entry {
        var $days_mask_int {
          value = $entry.days_mask|to_int
        }
      
        // SAFE mask test (no bitwise)
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
          if ($mask_on == 1) {
            // capture first entry for schema sanity
            conditional {
              if ($dbg_first_entry_raw == null) {
                var.update $dbg_first_entry_raw {
                  value = $entry
                }
              }
            }
          
            var.update $dbg_mask_pass {
              value = $dbg_mask_pass + 1
            }
          
            var $schedule_id_key {
              value = $entry.schedule_id|to_text
            }
          
            conditional {
              if ($schedule_by_id|has:$schedule_id_key) {
                var.update $dbg_schedule_found {
                  value = $dbg_schedule_found + 1
                }
              
                var $schedule {
                  value = $schedule_by_id|get:$schedule_id_key
                }
              
                // IMPORTANT: if your field name is not player_id, change here
                var $player_id_key {
                  value = $schedule.player_id|to_text
                }
              
                conditional {
                  if ($player_by_id|has:$player_id_key) {
                    var.update $dbg_player_found {
                      value = $dbg_player_found + 1
                    }
                  
                    var $player {
                      value = $player_by_id|get:$player_id_key
                    }
                  
                    // ----------------------------
                    // FULL-DAY FIX:
                    // If window is full-day, do NOT parse times.
                    // Anyone whose days_mask includes today counts.
                    // ----------------------------
                    conditional {
                      if ($is_full_day_window) {
                        var.update $dbg_eligible_entries_today {
                          value = $dbg_eligible_entries_today + 1
                        }
                      
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
                          if ($eff_club_id != null) {
                            var $club_key {
                              value = $eff_club_id|to_text
                            }
                          
                            var $player_id_txt {
                              value = $player.id|to_text
                            }
                          
                            var $cur_ids {
                              value = []
                            }
                          
                            conditional {
                              if ($expected_player_ids_by_club|has:$club_key) {
                                var.update $cur_ids {
                                  value = $expected_player_ids_by_club|get:$club_key
                                }
                              }
                            }
                          
                            var $already_present {
                              value = false
                            }
                          
                            conditional {
                              if ($cur_ids|contains:$player_id_txt) {
                                var.update $already_present {
                                  value = true
                                }
                              }
                            }
                          
                            conditional {
                              if ($already_present == false) {
                                var.update $dbg_added {
                                  value = $dbg_added + 1
                                }
                              
                                array.push $cur_ids {
                                  value = $player_id_txt
                                }
                              
                                var.update $expected_player_ids_by_club {
                                  value = $expected_player_ids_by_club|set:$club_key:$cur_ids
                                }
                              
                                var.update $expected_count_by_club {
                                  value = $expected_count_by_club|set:$club_key:($cur_ids|count)
                                }
                              
                                // min rating
                                conditional {
                                  if ($expected_min_rating_by_club|has:$club_key == false) {
                                    var.update $expected_min_rating_by_club {
                                      value = $expected_min_rating_by_club|set:$club_key:$player.rating
                                    }
                                  }
                                }
                              
                                conditional {
                                  if ($expected_min_rating_by_club|has:$club_key) {
                                    conditional {
                                      if ($player.rating < ($expected_min_rating_by_club|get:$club_key)) {
                                        var.update $expected_min_rating_by_club {
                                          value = $expected_min_rating_by_club|set:$club_key:$player.rating
                                        }
                                      }
                                    }
                                  }
                                }
                              
                                // max rating
                                conditional {
                                  if ($expected_max_rating_by_club|has:$club_key == false) {
                                    var.update $expected_max_rating_by_club {
                                      value = $expected_max_rating_by_club|set:$club_key:$player.rating
                                    }
                                  }
                                }
                              
                                conditional {
                                  if ($expected_max_rating_by_club|has:$club_key) {
                                    conditional {
                                      if ($player.rating > ($expected_max_rating_by_club|get:$club_key)) {
                                        var.update $expected_max_rating_by_club {
                                          value = $expected_max_rating_by_club|set:$club_key:$player.rating
                                        }
                                      }
                                    }
                                  }
                                }
                              }
                            }
                          }
                        }
                      
                        // Skip the rest of time parsing for this entry
                        continue
                      }
                    }
                  
                    // ----------------------------
                    // TIME PARSE PATH (only used when NOT full-day)
                    // ----------------------------
                    var $st_txt {
                      value = $entry.start_time|to_text|trim
                    }
                  
                    var $et_txt {
                      value = $entry.end_time|to_text|trim
                    }
                  
                    conditional {
                      if (($st_txt == null) || ($st_txt == "")) {
                        var.update $dbg_missing_start_time {
                          value = $dbg_missing_start_time + 1
                        }
                      
                        conditional {
                          if ($dbg_first_missing_time_entry == null) {
                            var.update $dbg_first_missing_time_entry {
                              value = {
                                entry_id   : $entry.id
                                schedule_id: $entry.schedule_id
                                club_id    : $entry.club_id
                                start_time : $entry.start_time
                                end_time   : $entry.end_time
                              }
                            }
                          }
                        }
                      
                        continue
                      }
                    }
                  
                    // normalize
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
                  
                    // If end_time missing, try "5PM-9PM" in start_time
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
                  
                    // default end
                    conditional {
                      if (($et_raw == null) || ($et_raw == "")) {
                        var.update $et_raw {
                          value = "11PM"
                        }
                      }
                    }
                  
                    // Whitelist: skip junk strings that aren't time-like
                    conditional {
                      if (($st_raw|contains:"AM" == false) && ($st_raw|contains:"PM" == false) && ($st_raw|contains:":" == false)) {
                        // count as parse_fail for TODAY entries
                        var.update $dbg_parse_fail {
                          value = $dbg_parse_fail + 1
                        }
                      
                        conditional {
                          if ($dbg_first_parse_fail == null) {
                            var.update $dbg_first_parse_fail {
                              value = {
                                entry_id   : $entry.id
                                schedule_id: $entry.schedule_id
                                club_id    : $entry.club_id
                                st_txt     : $st_txt
                                et_txt     : $et_txt
                                st_raw     : $st_raw
                                et_raw     : $et_raw
                              }
                            }
                          }
                        }
                      
                        continue
                      }
                    }
                  
                    // AM/PM flags
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
                  
                    // remove AM/PM
                    var $st_clean {
                      value = $st_raw|replace:"AM":""|replace:"PM":""
                    }
                  
                    var $et_clean {
                      value = $et_raw|replace:"AM":""|replace:"PM":""
                    }
                  
                    // split hour/min
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
                        var.update $dbg_parse_fail {
                          value = $dbg_parse_fail + 1
                        }
                      
                        conditional {
                          if ($dbg_first_parse_fail == null) {
                            var.update $dbg_first_parse_fail {
                              value = {
                                entry_id   : $entry.id
                                schedule_id: $entry.schedule_id
                                club_id    : $entry.club_id
                                st_txt     : $st_txt
                                et_txt     : $et_txt
                                st_raw     : $st_raw
                                et_raw     : $et_raw
                                st_clean   : $st_clean
                                et_clean   : $et_clean
                                st_parts   : $st_parts
                                et_parts   : $et_parts
                                st_hour_str: $st_hour_str
                                et_hour_str: $et_hour_str
                                st_min_str : $st_min_str
                                et_min_str : $et_min_str
                              }
                            }
                          }
                        }
                      
                        continue
                      }
                    }
                  
                    // convert to 24h
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
                  
                    // overlap check
                    conditional {
                      if (($start_min <= $today_end_minutes) && ($end_min >= $today_start_minutes)) {
                        var.update $dbg_eligible_entries_today {
                          value = $dbg_eligible_entries_today + 1
                        }
                      
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
                          if ($eff_club_id != null) {
                            var $club_key {
                              value = $eff_club_id|to_text
                            }
                          
                            var $player_id_txt {
                              value = $player.id|to_text
                            }
                          
                            var $cur_ids {
                              value = []
                            }
                          
                            conditional {
                              if ($expected_player_ids_by_club|has:$club_key) {
                                var.update $cur_ids {
                                  value = $expected_player_ids_by_club|get:$club_key
                                }
                              }
                            }
                          
                            var $already_present {
                              value = false
                            }
                          
                            conditional {
                              if ($cur_ids|contains:$player_id_txt) {
                                var.update $already_present {
                                  value = true
                                }
                              }
                            }
                          
                            conditional {
                              if ($already_present == false) {
                                var.update $dbg_added {
                                  value = $dbg_added + 1
                                }
                              
                                array.push $cur_ids {
                                  value = $player_id_txt
                                }
                              
                                var.update $expected_player_ids_by_club {
                                  value = $expected_player_ids_by_club|set:$club_key:$cur_ids
                                }
                              
                                var.update $expected_count_by_club {
                                  value = $expected_count_by_club|set:$club_key:($cur_ids|count)
                                }
                              
                                // min/max rating
                                conditional {
                                  if ($expected_min_rating_by_club|has:$club_key == false) {
                                    var.update $expected_min_rating_by_club {
                                      value = $expected_min_rating_by_club|set:$club_key:$player.rating
                                    }
                                  }
                                }
                              
                                conditional {
                                  if ($expected_min_rating_by_club|has:$club_key) {
                                    conditional {
                                      if ($player.rating < ($expected_min_rating_by_club|get:$club_key)) {
                                        var.update $expected_min_rating_by_club {
                                          value = $expected_min_rating_by_club|set:$club_key:$player.rating
                                        }
                                      }
                                    }
                                  }
                                }
                              
                                conditional {
                                  if ($expected_max_rating_by_club|has:$club_key == false) {
                                    var.update $expected_max_rating_by_club {
                                      value = $expected_max_rating_by_club|set:$club_key:$player.rating
                                    }
                                  }
                                }
                              
                                conditional {
                                  if ($expected_max_rating_by_club|has:$club_key) {
                                    conditional {
                                      if ($player.rating > ($expected_max_rating_by_club|get:$club_key)) {
                                        var.update $expected_max_rating_by_club {
                                          value = $expected_max_rating_by_club|set:$club_key:$player.rating
                                        }
                                      }
                                    }
                                  }
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  
    // ----------------------------
    // C) Live sessions RSVP sum
    // ----------------------------
    db.query session {
      where = 1 == 1
      return = {type: "list"}
    } as $sessions
  
    var $live_by_club {
      value = {}
    }
  
    foreach ($sessions) {
      each as $sess {
        var $st_txt {
          value = $sess.start_time|to_text|trim
        }
      
        var $et_txt {
          value = $sess.end_time|to_text|trim
        }
      
        conditional {
          if (($et_txt == null) || ($et_txt == "")) {
            var.update $et_txt {
              value = "11PM"
            }
          }
        }
      
        conditional {
          if (($st_txt == null) || ($st_txt == "") || ($et_txt == null) || ($et_txt == "")) {
            continue
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
      
        // whitelist (skip junk)
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
      
        var $s_start_min {
          value = ($st_hour * 60) + $st_min
        }
      
        var $s_end_min {
          value = ($et_hour * 60) + $et_min
        }
      
        conditional {
          if (($s_start_min <= $today_end_minutes) && ($s_end_min >= $today_start_minutes)) {
            var $c_key {
              value = $sess.club_id|to_text
            }
          
            var $current_rsvp {
              value = 0
            }
          
            conditional {
              if ($live_by_club|has:$c_key) {
                var.update $current_rsvp {
                  value = $live_by_club|get:$c_key
                }
              }
            }
          
            var.update $live_by_club {
              value = $live_by_club
                |set:$c_key:$current_rsvp + $sess.rsvp_count
            }
          }
        }
      }
    }
  
    // ----------------------------
    // D) Merge with clubs
    // ----------------------------
    db.query club {
      where = 1 == 1
      return = {type: "list"}
    } as $clubs
  
    var $result {
      value = [
        {
          "club_id": -1,
          "club_name": "__DEBUG__",
          "city": "",
          "live_rsvp_count": 0,
          "expected_count": 0,
          "expected_player_ids": [],
          "min_rating": null,
          "max_rating": null,
          "crowd_level": "DEBUG",
          "window_start_minutes": 0,
          "window_end_minutes": 0,
          "timezone": "",
          "is_active_window": false,
          "debug": {
            "entries_count": $dbg_entries_count,
            "mask_pass": $dbg_mask_pass,
            "schedule_found": $dbg_schedule_found,
            "player_found": $dbg_player_found,
            "eligible_entries_today": $dbg_eligible_entries_today,
            "added": $dbg_added,
            "today_mask": $today_mask,
            "weekday_raw": $today_weekday_raw,
            "missing_start_time": $dbg_missing_start_time,
            "first_missing_time_entry": $dbg_first_missing_time_entry,
            "parse_fail_today": $dbg_parse_fail,
            "first_parse_fail_today": $dbg_first_parse_fail,
            "first_entry_raw": $dbg_first_entry_raw,
            "full_day_window": $is_full_day_window
          }
        }
      ]
    }
  
    foreach ($clubs) {
      each as $club {
        conditional {
          if ($club.is_active != true) {
            continue
          }
        }
      
        var $c_id_key {
          value = $club.id|to_text
        }
      
        var $exp_count {
          value = 0
        }
      
        var $min_r {
          value = null
        }
      
        var $max_r {
          value = null
        }
      
        var $expected_player_ids {
          value = []
        }
      
        conditional {
          if ($expected_count_by_club|has:$c_id_key) {
            var.update $exp_count {
              value = $expected_count_by_club|get:$c_id_key
            }
          }
        }
      
        conditional {
          if ($expected_min_rating_by_club|has:$c_id_key) {
            var.update $min_r {
              value = $expected_min_rating_by_club|get:$c_id_key
            }
          }
        }
      
        conditional {
          if ($expected_max_rating_by_club|has:$c_id_key) {
            var.update $max_r {
              value = $expected_max_rating_by_club|get:$c_id_key
            }
          }
        }
      
        conditional {
          if ($expected_player_ids_by_club|has:$c_id_key) {
            var.update $expected_player_ids {
              value = $expected_player_ids_by_club|get:$c_id_key
            }
          }
        }
      
        var $live_count {
          value = 0
        }
      
        conditional {
          if ($live_by_club|has:$c_id_key) {
            var.update $live_count {
              value = $live_by_club|get:$c_id_key
            }
          }
        }
      
        var $crowd {
          value = "Dead"
        }
      
        conditional {
          if ($live_count >= 10) {
            var.update $crowd {
              value = "Popping"
            }
          }
        }
      
        conditional {
          if (($live_count < 10) && ($live_count >= 4)) {
            var.update $crowd {
              value = "Active"
            }
          }
        }
      
        conditional {
          if (($live_count < 4) && ($exp_count >= 6)) {
            var.update $crowd {
              value = "Likely Busy"
            }
          }
        }
      
        conditional {
          if (($live_count < 4) && ($exp_count < 6) && ($exp_count >= 2)) {
            var.update $crowd {
              value = "Chill"
            }
          }
        }
      
        array.push $result {
          value = {
            club_id             : $club.id
            club_name           : $club.name
            city                : $club.city
            live_rsvp_count     : $live_count
            expected_count      : $exp_count
            expected_player_ids : $expected_player_ids
            min_rating          : $min_r
            max_rating          : $max_r
            crowd_level         : $crowd
            window_start_minutes: $today_start_minutes
            window_end_minutes  : $today_end_minutes
            timezone            : $timezone
            is_active_window    : $is_active_window
          }
        }
      }
    }
  
    // ----------------------------
    // E) Sort + respond
    // ----------------------------
    var $tmp_sorted {
      value = $result|sort:"expected_count"|reverse
    }
  
    var $sorted_result {
      value = $tmp_sorted|sort:"live_rsvp_count"|reverse
    }
  }

  response = $sorted_result
}