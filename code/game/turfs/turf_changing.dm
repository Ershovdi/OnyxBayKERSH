/turf/proc/ReplaceWithLattice()
	var base_turf = get_base_turf_by_area(src)
	if(type != base_turf)
		ChangeTurf(get_base_turf_by_area(src))
	if(!locate(/obj/structure/lattice) in src)
		new /obj/structure/lattice(src)

// Removes all signs of lattice on the pos of the turf -Donkieyo
/turf/proc/RemoveLattice()
	var/obj/structure/lattice/L = locate(/obj/structure/lattice, src)
	if(L)
		qdel(L)
// Called after turf replaces old one
/turf/proc/post_change()
	levelupdate()
	var/turf/simulated/open/T = GetAbove(src)
	if(istype(T))
		T.update_icon()

//Creates a new turf
/turf/proc/ChangeTurf(turf/N, tell_universe = TRUE, force_lighting_update = FALSE)
	ASSERT(N)

	// This makes sure that turfs are not changed to space when one side is part of a zone
	if(ispath(N, /turf/space))
		var/turf/below = GetBelow(src)
		if(istype(below) && !istype(below,/turf/space))
			N = below.density ? /turf/simulated/floor/plating/airless : /turf/simulated/open

	var/obj/fire/old_fire = fire
	var/old_density = density
	var/old_opacity = opacity
	var/old_dynamic_lighting = dynamic_lighting
	var/old_affecting_lights = affecting_lights
	var/old_lighting_overlay = lighting_overlay
	var/old_corners = corners

//	log_debug("Replacing [src.type] with [N]")

	changing_turf = TRUE

	if(connections) connections.erase_all()

	overlays.Cut()
	underlays.Cut()
	if(istype(src,/turf/simulated))
		//Yeah, we're just going to rebuild the whole thing.
		//Despite this being called a bunch during explosions,
		//the zone will only really do heavy lifting once.
		var/turf/simulated/S = src
		if(S.zone) S.zone.rebuild()

	// Closest we can do as far as giving sane alerts to listeners. In particular, this calls Exited and moved events in a self-consistent way.
	var/list/old_contents = list()
	for(var/atom/movable/A in src)
		old_contents += A
		A.forceMove(null)

	var/old_opaque_counter = opaque_counter

	var/old_lookups = comp_lookup?.Copy()
	var/old_components = datum_components?.Copy()
	var/old_signals = signal_procs?.Copy()
	comp_lookup?.Cut()
	datum_components?.Cut()
	signal_procs?.Cut()

	// Run the Destroy() chain.
	qdel(src)

	var/turf/simulated/W = new N(src)

	comp_lookup = old_lookups
	datum_components = old_components
	signal_procs = old_signals

	for(var/atom/movable/A in old_contents)
		A.forceMove(W)

	for(var/atom/movable/A in old_contents)
		A.forceMove(W)

	W.opaque_counter = old_opaque_counter
	W.RecalculateOpacity()

	if(ispath(N, /turf/simulated))
		if(old_fire)
			fire = old_fire
		if(istype(W, /turf/simulated/floor))
			W.RemoveLattice()
	else if(old_fire)
		old_fire.RemoveFire()

	if(tell_universe)
		GLOB.universe.OnTurfChange(W)

	SSair.mark_for_update(src) //handle the addition of the new turf.

	for(var/turf/space/S in range(W,1))
		S.update_starlight()

	W.post_change()
	. = W

	if(lighting_overlays_initialised)
		lighting_overlay = old_lighting_overlay
		if (lighting_overlay && lighting_overlay.loc != src)
			// This is a hack, but I can't figure out why the fuck they're not on the correct turf in the first place.
			lighting_overlay.forceMove(src)

		affecting_lights = old_affecting_lights
		corners = old_corners

		if ((old_opacity != opacity) || (dynamic_lighting != old_dynamic_lighting) || force_lighting_update)
			reconsider_lights()

		if (dynamic_lighting != old_dynamic_lighting)
			if (dynamic_lighting)
				lighting_build_overlay()
			else
				lighting_clear_overlay()

	for(var/turf/T in RANGE_TURFS(1, src))
		T.update_icon()

	SEND_SIGNAL(src, SIGNAL_TURF_CHANGED, src, old_density, density, old_opacity, opacity)

/turf/proc/transport_properties_from(turf/other)
	if(!istype(other, src.type))
		return 0
	src.set_dir(other.dir)
	src.icon_state = other.icon_state
	src.icon = other.icon
	src.overlays = other.overlays.Copy()
	src.underlays = other.underlays.Copy()
	if(other.decals)
		src.decals = other.decals.Copy()
		src.update_icon()
	return 1

//I would name this copy_from() but we remove the other turf from their air zone for some reason
/turf/simulated/transport_properties_from(turf/simulated/other)
	if(!..())
		return 0

	if(other.zone)
		if(!src.air)
			src.make_air()
		src.air.copy_from(other.zone.air)
		other.zone.remove(other)
	return 1


//No idea why resetting the base appearence from New() isn't enough, but without this it doesn't work
/turf/simulated/shuttle/wall/corner/transport_properties_from(turf/simulated/other)
	. = ..()
	reset_base_appearance()
