/datum/vote/map
	name = "map"

/datum/vote/map/can_run(mob/creator, automatic)
	if(!config.game.map_switching)
		return FALSE
	if(!automatic && !is_admin(creator))
		return FALSE // Must be an admin.
	return ..()

/datum/vote/map/setup_vote()
	for(name in GLOB.all_maps)
		var/datum/map/M = GLOB.all_maps[name]
		if(M.can_be_voted)
			choices += M.name
	..()

/datum/vote/map/report_result()
	if(..())
		return 1
	var/datum/map/M = GLOB.all_maps[result[1]]

	if (M)
		to_world("<span class='notice'>Map has been changed to: <b>[M.name]</b></span>")
		fdel("data/use_map")
		text2file("[M.type]", "data/use_map")

//Used by the ticker.
/datum/vote/map/end_game
	manual_allowed = 0

/datum/vote/map/end_game/report_result()
	SSticker.end_game_state = END_GAME_READY_TO_END
	. = ..()

/datum/vote/map/end_game/start_vote()
	SSticker.end_game_state = END_GAME_AWAITING_MAP
	..()
