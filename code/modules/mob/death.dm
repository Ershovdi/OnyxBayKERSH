//This is the proc for gibbing a mob. Cannot gib ghosts.
//added different sort of gibs and animations. N
/mob/proc/gib(anim = "gibbed-m", do_gibs = FALSE)
	if(status_flags & GODMODE)
		return
	death(1)
	ADD_TRANSFORMATION_MOVEMENT_HANDLER(src)
	icon = null
	set_invisibility(101)
	update_canmove()
	remove_from_dead_mob_list()

	var/atom/movable/overlay/animation = null
	animation = new(loc)
	animation.icon_state = "blank"
	animation.icon = 'icons/mob/mob.dmi'
	animation.master = src
	playsound(src, SFX_GIB, 75, 1)

	flick(anim, animation)
	if(do_gibs)
		gibs(loc, dna)

	addtimer(CALLBACK(src, .proc/check_delete, animation), 15)

/mob/proc/check_delete(atom/movable/overlay/animation)
	if(animation)
		qdel(animation)
	if(src)
		qdel(src)

//This is the proc for turning a mob into ash. Mostly a copy of gib code (above).
//Originally created for wizard disintegrate. I've removed the virus code since it's irrelevant here.
//Dusting robots does not eject the MMI, so it's a bit more powerful than gib() /N
/mob/proc/dust(anim = "dust-m", remains = /obj/effect/decal/cleanable/ash)
	if(status_flags & GODMODE)
		return
	death(1)
	var/atom/movable/overlay/animation = null
	ADD_TRANSFORMATION_MOVEMENT_HANDLER(src)
	icon = null
	set_invisibility(101)

	animation = new(loc)
	animation.icon_state = "blank"
	animation.icon = 'icons/mob/mob.dmi'
	animation.master = src

	flick(anim, animation)
	new remains(loc)

	remove_from_dead_mob_list()
	addtimer(CALLBACK(src, .proc/check_delete, animation), 15)


/mob/proc/death(gibbed, deathmessage = "seizes up and falls limp...", show_dead_message = "You have died.")

	if(is_ooc_dead())
		return 0

	facing_dir = null

	if(!gibbed && deathmessage != "no message") // This is gross, but reliable. Only brains use it.
		src.visible_message("<b>\The [src.name]</b> [deathmessage]")

	set_stat(DEAD)
	reset_plane_and_layer()
	update_canmove()

	dizziness = 0
	jitteriness = 0

	set_sight(sight|SEE_TURFS|SEE_MOBS|SEE_OBJS)
	set_see_in_dark(8)
	set_see_invisible(SEE_INVISIBLE_LEVEL_TWO)

	drop_r_hand()
	drop_l_hand()

	if(isliving(src))
		var/mob/living/L = src
		L.handle_hud_icons_health()

	timeofdeath = world.time
	if(mind) mind.store_memory("Time of death: [stationtime2text()]", 0)
	switch_from_living_to_dead_mob_list()

	update_icon()

	if(SSticker.mode)
		SSticker.mode.check_win()
	to_chat(src,"<span class='deadsay'>[show_dead_message]</span>")
	return 1
