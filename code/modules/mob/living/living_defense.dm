#define ARMOR_HALLOS_COEFFICIENT 0.4
#define ARMOR_GDR_COEFFICIENT 0.1

#define ABSOLUTE_ARMOR_EFFICIENCY 0
//Efficiency of ABSOLUTE (POST bulk combat update) armour, not tested thoroughtly but value of 5 with RAE of 0 should give similiar experience to post bulk combat update

#define RELATIVE_ARMOR_EFFICIENCY 1
//Efficiency of RELATIVE (PRE bulk combat update) armour, value of 1 is how it was with AAE of 0, to turn it off set valute to 0 (It will still have the armour breaking behaviour)

//This calculation replaces old run_armor_check in favor of more complex and better system
//If you need to do something else with armor - just use getarmor() proc and do with those numbers all you want
//Random absorb system was a cancer, and was removed from all across the codebase. Don't recreate it. Clockrigger 2019

#define ARMOR_MESSAGE_COOLDOWN 0.5 SECONDS

/mob/living/var/last_armor_message

/mob/living/proc/armor_message(msg1, msg2)
	if(world.time < last_armor_message)
		return FALSE
	last_armor_message = world.time + ARMOR_MESSAGE_COOLDOWN
	if(msg2)
		visible_message(msg1, msg2)
	else
		show_message(msg1, 1)

/mob/living/proc/damage_through_armor(// damage + damagetype seems to be some old system of handling damage, rather than doing it throught dmg_types (a list)
	damage					= 0,
	damagetype				= BRUTE,
	def_zone				= null,
	attack_flag				= ARMOR_MELEE,
	armor_pen				= 0,
	used_weapon				= null,
	sharp					= FALSE,
	edge					= FALSE,
	wounding_multiplier		= 1,
	list/dmg_types			= list(),
	return_continuation		= FALSE,
	dir_mult				= 1,
	post_pen_mult			= 1
	)

	if(armor_pen <= 0)
		armor_pen = 0.1 // if HYBRID armour system were to be chosen armour penetration of 0 could fuck up some calculations, negative one ... well I am expecting out of artists
		//log_debug("[used_weapon] applied damage to [name] with a nonpositive armor penetration !!")
		//this will flood logs until we change armour pen to be above 0

	if(damage) // If damage is defined, we add it to the list
		if(!dmg_types[damagetype])
			dmg_types += damagetype
		dmg_types[damagetype] += damage
	var/total_dmg = 0
	for(var/dmg_type in dmg_types)
		total_dmg += dmg_types[dmg_type]
	if(!total_dmg)
		return FALSE

	//Used for simple/super mobs do to their armor being checked twice
	var/armor_times_mod = 1

//	if(istype(src,/mob/living/simple_animal/) || istype(src,/mob/living/carbon/superior_animal/))
//		armor_times_mod = 0.5 // a thing from the past . . . why do we have this ?

	//GDR - guaranteed damage reduction. It's a value that deducted from damage before all calculations
	var/armor = getarmor(def_zone, attack_flag)
	var/armor_effectiveness = max(0, ((armor * armor_times_mod) - armor_pen) * RELATIVE_ARMOR_EFFICIENCY)
	var/absolute_armor = max(0, ((((armor) * armor_times_mod) - armor_pen) * ABSOLUTE_ARMOR_EFFICIENCY) / armor_pen)

	var/ablative_armor = getarmorablative(def_zone, attack_flag) * (100 - armor_pen) / 100

	var/final_damage = 0 //final summary of damage after all the calculations, for armour message

//this will trigger with EVERY ATTACK, kill NPC's via debug verbs
//	message_admins("##########################################")
//	for(var/dmg_type in dmg_types)
//		message_admins("dmg_type [dmg_type] = dmg [dmg_types[dmg_type]]")

	if(istype(src,/mob/living/simple_animal/) || istype(src,/mob/living/carbon/superior_animal/)) //PVE extra damages
		if(armor + 1 < armor_pen) //overpen damage
			for(var/dmg_type in dmg_types)
				dmg_types[dmg_type] += (armor_pen - armor) / dmg_types.len //we split overpen damage into other damage types equally, this might need adjustment if we chose to have a more ABSOLUTE heavy armor system
		if(dmg_types[HALLOSS]>0) //PvE hallos damage
			var/agony_armor_effectiveness = max(0, ((armor * armor_times_mod) - armor_pen) * RELATIVE_ARMOR_EFFICIENCY)
			var/agony_absolute_armor = max(0, (((armor * armor_times_mod) - armor_pen) * ABSOLUTE_ARMOR_EFFICIENCY) / armor_pen)
			var/mob_agony_gamage = max(dmg_types[HALLOSS] * ARMOR_GDR_COEFFICIENT,round ( ( dmg_types[HALLOSS] * ( 100 - agony_armor_effectiveness ) ) / 100 - agony_absolute_armor))
			adjustHalLoss(mob_agony_gamage)
			final_damage+=mob_agony_gamage
//	alternative way of doing it similiar to overpen above
//			if(dmg_types.len <= 1) //if we have no other damage types other than HALLOSS we doin BRUTE, TODO: give every weapon with just HALLOSS a secondary damage type set to 0
//				dmg_types[BRUTE]=0
//			for(var/dmg_type in dmg_types)
//				dmg_types[dmg_type] += dmg_types[HALLOSS] / dmg_types.len-1
			dmg_types[HALLOSS] = 0

	for(var/dmg_type in dmg_types)
		var/dmg = dmg_types[dmg_type]
		if(dmg)
			if(armor_effectiveness == 0)//No armor? Damage as usual
				apply_damage(dmg * post_pen_mult, dmg_type, def_zone, 1, wounding_multiplier, sharp, edge)
				final_damage+=dmg * post_pen_mult
				if(ishuman(src) && def_zone)
					var/mob/living/carbon/human/H = src
					var/obj/item/organ/external/o = H.get_organ(def_zone)
					if (o && o.status & ORGAN_SPLINTED && dmg >= 20)
						visible_message(SPAN_WARNING("The splints break off [src] after being hit!"),
								SPAN_WARNING("Your splints break off after being hit!"))
						o.status &= ~ORGAN_SPLINTED
			//Here we split damage in two parts, where armor value will determine how much damage will get through
			else

				//Pain part of the damage, meaning that it is the pain caused by brute/burn/etc, that simulates impact from armor absorbtion
				//For balance purposes, it's lowered by ARMOR_HALLOS_COEFFICIENT
				if(!(dmg_type == HALLOSS))
					var/agony_gamage = max(dmg * ARMOR_GDR_COEFFICIENT * ARMOR_HALLOS_COEFFICIENT,round( ( dmg * armor_effectiveness * ARMOR_HALLOS_COEFFICIENT * clamp((get_specific_organ_efficiency(OP_NERVE, def_zone) / 100), 0.5, 1.5) / 100) - absolute_armor * ARMOR_HALLOS_COEFFICIENT))
					adjustHalLoss(agony_gamage)

				//Actual part of the damage that passed through armor
				var/actual_damage = max(dmg * ARMOR_GDR_COEFFICIENT,round ( ( dmg * ( 100 - armor_effectiveness ) ) / 100 - absolute_armor))
				apply_damage(actual_damage * post_pen_mult, dmg_type, def_zone, used_weapon, sharp, edge)
				if(ishuman(src) && def_zone && actual_damage >= 20)
					var/mob/living/carbon/human/H = src
					var/obj/item/organ/external/o = H.get_organ(def_zone)
					if (o && o.status & ORGAN_SPLINTED)
						visible_message(SPAN_WARNING("The splints break off [src] after being hit!"),
								SPAN_WARNING("Your splints break off after being hit!"))
						o.status &= ~ORGAN_SPLINTED
				final_damage+=actual_damage






	var/effective_armor = 100 - (final_damage / total_dmg) * 100


	//Feedback
	//In order to show both target and everyone around that armor is actually working, we are going to send message for both of them
	//Goon/tg chat should take care of spam issue on this one
	switch(effective_armor)
		if(89 to INFINITY)
			armor_message(SPAN_NOTICE("[src] armor absorbs the blow!"),
							SPAN_NOTICE("Your armor absorbed the impact!"))
		if(74 to 89)
			armor_message(SPAN_NOTICE("[src] armor easily absorbs the blow!"),
							SPAN_NOTICE("Your armor greatly reduced the impact!"))
		if(49 to 74)
			armor_message(SPAN_NOTICE("[src] armor absorbs most of the damage!"),
							SPAN_NOTICE("Your armor protects you from the impact!"))
		if(24 to 49)
			armor_message(SPAN_NOTICE("[src] armor absorbs fair bit of the damage!"),
							SPAN_NOTICE("Your armor reduced the impact!"))
		if(10 to 24)
			armor_message(SPAN_NOTICE("[src] armor reduces the impact by a little."),
							SPAN_NOTICE("Your armor reduced the impact a little."))
		if(-INFINITY to 10)
			armor_message(SPAN_NOTICE("[src] armor was pierced !"),
							SPAN_NOTICE("Your armor didn't affect the impact at all !"))

//this will trigger with EVERY ATTACK, kill NPC's via debug verbs
//	message_admins("[used_weapon] VS [src] | def_zone=[def_zone] | total_dmg=[total_dmg] | final_dmg=[final_damage] | armor=[armor] | absolute_armor=[absolute_armor] | armor_pen=[armor_pen] | armor_effectiveness=[armor_effectiveness] | effective_armor=[effective_armor]")
//	message_admins("##########################################")


//if null is passed for def_zone, then this should return something appropriate for all zones (e.g. area effect damage)
/mob/living/proc/getarmor(var/def_zone, var/type)
	return 1 //once we start playing with ABSOLUTE ARMOUR this should be set to the "middle", think of it like 0 AP in RELATIVE system or 1 AD in ABSOLUTE

/mob/living/proc/getarmorablative(var/def_zone, var/type)
	return FALSE

/mob/living/proc/damageablative(var/def_zone, var/damage)
	return FALSE

/mob/living/simple_animal/getarmor(var/def_zone, var/type)
	return src.armor[type]

/mob/living/carbon/superior_animal/getarmor(var/def_zone, var/type)
	return src.armor[type]

/mob/living/proc/hit_impact(damage, dir)
	if(incapacitated(INCAPACITATION_DEFAULT|INCAPACITATION_BUCKLED_PARTIALLY))
		return
	shake_animation(damage)


 // return PROJECTILE_CONTINUE if bullet should continue flying
/mob/living/bullet_act(obj/item/projectile/P, var/def_zone_hit)
	var/hit_dir = get_dir(P, src)

	if (P.is_hot() >= HEAT_MOBIGNITE_THRESHOLD)
		IgniteMob()

	//Being hit while using a deadman switch
	if(istype(get_active_hand(),/obj/item/device/assembly/signaler))
		var/obj/item/device/assembly/signaler/signaler = get_active_hand()
		if(signaler.deadman && prob(80))
			log_and_message_admins("has triggered a signaler deadman's switch")
			src.visible_message(SPAN_WARNING("[src] triggers their deadman's switch!"))
			signaler.signal()

	var/agony = P.damage_types[HALLOSS] ? P.damage_types[HALLOSS] : 0
	//Stun Beams
	if(P.taser_effect)
		stun_effect_act(0, agony, def_zone_hit, P, armor_pen = P.armor_penetration, damage_already_applied = TRUE)
		damage_through_armor(def_zone = def_zone_hit, attack_flag = P.check_armour, armor_pen = P.armor_penetration, used_weapon = P, sharp = is_sharp(P), edge = has_edge(P), wounding_multiplier = P.wounding_mult, dmg_types = P.damage_types)
		to_chat(src, SPAN_WARNING("You have been hit by [P]!"))
		qdel(P)
		return TRUE

	if(P.knockback && hit_dir)
		throw_at(get_edge_target_turf(src, hit_dir), P.knockback, P.knockback)

	P.on_hit(src, def_zone_hit)

	//Armor and damage
	if(!P.nodamage)
		if (!(P.testing))
			hit_impact(P.get_structure_damage(), hit_dir)
		for(var/damage_type in P.damage_types)
			var/damage = P.damage_types[damage_type]
			var/dmult = 1
			if(faction in P.effective_faction)
				dmult += P.damage_mult
			if(is_type_in_list(src, P.supereffective_types, TRUE))
				dmult += P.supereffective_mult
			damage *= dmult
		hit_impact(P.get_structure_damage(), hit_dir)
		return damage_through_armor(def_zone = def_zone_hit, attack_flag = P.check_armour, armor_pen = P.armor_penetration, used_weapon = P, sharp = is_sharp(P), edge = has_edge(P), wounding_multiplier = P.wounding_mult, dmg_types = P.damage_types, return_continuation = TRUE)

	return PROJECTILE_CONTINUE

//Handles the effects of "stun" weapons
/mob/living/proc/stun_effect_act(var/stun_amount, var/agony_amount, var/def_zone, var/used_weapon=null, var/armor_pen=1, var/damage_already_applied=FALSE)
	flash_pain()

	//For not bloating damage_through_armor here is simple armor calculation for stun time
	var/armor_coefficient = max(0, 1 - getarmor(def_zone, ARMOR_ENERGY) / 100)
	var/armor_absolut=max(0, (((getarmor(def_zone, ARMOR_ENERGY) - armor_pen) * ABSOLUTE_ARMOR_EFFICIENCY) / armor_pen)) // TODO use it

	//If armor is 100 or more, we just skeeping it
	if (stun_amount && armor_coefficient)

		Stun(stun_amount * armor_coefficient)
		Weaken(stun_amount * armor_coefficient)
		apply_effect(STUTTER, stun_amount * armor_coefficient)
		apply_effect(EYE_BLUR, stun_amount * armor_coefficient)

//	if (agony_amount && armor_coefficient && agony_amount * armor_coefficient > armor_absolut)
	if (agony_amount && armor_coefficient)
		if(damage_already_applied == FALSE)
			apply_damage(max(agony_amount * ARMOR_GDR_COEFFICIENT , agony_amount * armor_coefficient - armor_absolut), HALLOSS, def_zone, 0, used_weapon)

		apply_effect(STUTTER, agony_amount * armor_coefficient)
		apply_effect(EYE_BLUR, agony_amount * armor_coefficient)
		SEND_SIGNAL(src, COMSIG_LIVING_STUN_EFFECT)

/mob/living/proc/electrocute_act(var/shock_damage, var/obj/source, var/siemens_coeff = 1.0)
	  return 0 //only carbon liveforms have this proc

/mob/living/emp_act(severity)
	var/list/L = src.get_contents()
	for(var/obj/O in L)
		O.emp_act(severity)
	..()

/mob/living/proc/resolve_item_attack(obj/item/I, mob/living/user, var/target_zone)
	return target_zone

//Called when the mob is hit with an item in combat.
/mob/living/proc/hit_with_weapon(obj/item/I, mob/living/user, var/effective_force, var/hit_zone)
	visible_message(SPAN_DANGER("[src] has been [LAZYPICK(I.attack_verb) || "attacked"] with [I.name] by [user]!"))

	standard_weapon_hit_effects(I, user, effective_force, hit_zone)

	if(I.damtype == BRUTE && prob(33)) // Added blood for whacking non-humans too
		var/turf/simulated/location = get_turf(src)
		if(istype(location)) location.add_blood_floor(src)

	return

//returns 0 if the effects failed to apply for some reason, 1 otherwise.
/mob/living/proc/standard_weapon_hit_effects(obj/item/I, mob/living/user, var/effective_force, var/hit_zone)
	if(!effective_force)
		return FALSE
	//Hulk modifier
//	if(HULK in user.mutations)
//		effective_force *= 2

	//Apply weapon damage
	if (damage_through_armor(effective_force, I.damtype, hit_zone, ARMOR_MELEE, I.armor_penetration, used_weapon = I, sharp = is_sharp(I), edge = has_edge(I), post_pen_mult = I.post_penetration_dammult))
		return TRUE
	else
		return FALSE

//this proc handles being hit by a thrown atom
/mob/living/hitby(atom/movable/AM as mob|obj,var/speed = THROWFORCE_SPEED_DIVISOR)//Standardization and logging -Sieve
	if(istype(AM,/obj/))
		var/obj/O = AM
		var/dtype = O.damtype
		var/throw_damage = O.throwforce //Are minium damage we do is baseline in cases were we do more damage we do more

		var/miss_chance = 15
		if (O.throw_source)
			var/distance = get_dist(O.throw_source, loc)
			miss_chance = max(15*(distance-4), 0)

		if (prob(miss_chance))
			visible_message("\blue \The [O] misses [src] narrowly!")
			playsound(src, "miss_sound", 50, 1, -6)
			return

		if (O.is_hot() >= HEAT_MOBIGNITE_THRESHOLD)
			IgniteMob()

		src.visible_message(SPAN_WARNING("[src] has been hit by [O]."))
		var/ppd = 1
		if(isitem(O))
			var/obj/item/thingytocheck = O
			ppd = thingytocheck.post_penetration_dammult
		damage_through_armor(throw_damage, dtype, null, ARMOR_MELEE, null, used_weapon = O, armor_pen = O.armor_penetration, sharp = is_sharp(O), edge = has_edge(O), post_pen_mult = ppd)

		O.throwing = 0		//it hit, so stop moving

		if(ismob(O.thrower))
			var/mob/M = O.thrower
			var/client/assailant = M.client
			if(assailant)
				src.attack_log += text("\[[time_stamp()]\] <font color='orange'>Has been hit with a [O], thrown by [M.name] ([assailant.ckey])</font>")
				M.attack_log += text("\[[time_stamp()]\] <font color='red'>Hit [src.name] ([src.ckey]) with a thrown [O]</font>")
				if(!ismouse(src))
					msg_admin_attack("[src.name] ([src.ckey]) was hit by a [O], thrown by [M.name] ([assailant.ckey]) (<A HREF='?_src_=holder;adminplayerobservecoodjump=1;X=[src.x];Y=[src.y];Z=[src.z]'>JMP</a>)")

		// Begin BS12 momentum-transfer code.
		var/mass = 1.5
		if(istype(O, /obj/item))
			var/obj/item/I = O
			mass = I.w_class/THROWNOBJ_KNOCKBACK_DIVISOR
		var/momentum = speed*mass

		if(O.throw_source && momentum >= THROWNOBJ_KNOCKBACK_SPEED)
			var/dir = get_dir(O.throw_source, src)

			visible_message(SPAN_WARNING("[src] staggers under the impact!"),SPAN_WARNING("You stagger under the impact!"))
			src.throw_at(get_edge_target_turf(src,dir),1,momentum)

			if(!O || !src) return

			if(O.sharp) //Projectile is suitable for pinning.
				//Handles embedding for non-humans and simple_animals.
				embed(O)

				var/turf/T = near_wall(dir,2)

				if(T)
					src.loc = T
					visible_message(SPAN_WARNING("[src] is pinned to the wall by [O]!"),SPAN_WARNING("You are pinned to the wall by [O]!"))
					src.anchored = TRUE
					src.pinned += O

/mob/living/proc/embed(var/obj/item/O, var/def_zone=null)
	if(O.wielded)
		return
	if(ismob(O.loc))
		var/mob/living/L = O.loc
		if(!L.unEquip(O, src))
			return
	O.forceMove(src)
	src.embedded += O
	src.visible_message(SPAN_DANGER("\The [O] embeds in the [src]!"))
	add_verb(src, /mob/proc/yank_out_object)
	O.on_embed(src)

//This is called when the mob is thrown into a dense turf
/mob/living/proc/turf_collision(var/turf/T, var/speed)
	src.take_organ_damage(speed*5)

/mob/living/proc/near_wall(var/direction,var/distance=1)
	var/turf/T = get_step(get_turf(src),direction)
	var/turf/last_turf = src.loc
	var/i = 1

	while(i>0 && i<=distance)
		if(T.density) //Turf is a wall!
			return last_turf
		i++
		last_turf = T
		T = get_step(T,direction)

	return 0

// End BS12 momentum-transfer code.
//A **lot** of the arguments for this are dead data used for human/superier mobs
/mob/living/attack_generic(mob/user, damage, attack_message, damagetype = BRUTE, attack_flag = ARMOR_MELEE, sharp = FALSE, edge = FALSE)

	if(!damage || !istype(user))
		return
	if(damagetype == BRUTE)
		adjustBruteLoss(damage)
	else
		adjustFireLoss(damage)
	user.attack_log += text("\[[time_stamp()]\] <font color='red'>attacked [src.name] ([src.ckey])</font>")
	src.attack_log += text("\[[time_stamp()]\] <font color='orange'>was attacked by [user.name] ([user.ckey])</font>")
	src.visible_message(SPAN_DANGER("[user] has [attack_message] [src]!"))
	user.do_attack_animation(src)
	spawn(1) updatehealth()
	return 1

/mob/living/proc/IgniteMob()
	if(fire_stacks > 0 && !on_fire)
		on_fire = TRUE
		set_light(light_range + 3, l_color = COLOR_RED)
		update_fire()

/mob/living/proc/ExtinguishMob()
	if(on_fire)
		on_fire = FALSE
		fire_stacks = 0
		set_light(max(0, light_range - 3))
		update_fire()

/mob/living/proc/update_fire()
	return
//	cut_overlay(image("icon"='icons/mob/OnFire.dmi', "icon_state"="Standing"))
//	if(on_fire)
//		add_overlay(image("icon"='icons/mob/OnFire.dmi', "icon_state"="Standing"))

/mob/living/proc/adjust_fire_stacks(add_fire_stacks) //Adjusting the amount of fire_stacks we have on person
    fire_stacks = CLAMP(fire_stacks + add_fire_stacks, FIRE_MIN_STACKS, FIRE_MAX_STACKS)

/mob/living/proc/handle_fire()
	if(never_stimulate_air)
		if (fire_stacks > 0)
			ExtinguishMob() //We dont simulate air thus we dont simulate fire
		return

	var/burn_temperature = fire_burn_temperature()
	var/thermal_protection = get_heat_protection(burn_temperature)

	if (thermal_protection < 1 && bodytemperature < burn_temperature && on_fire)
		bodytemperature += round(BODYTEMP_HEATING_MAX*(1-thermal_protection), 1)
		if(world.time >= next_onfire_brn)
			next_onfire_brn = world.time + 50
			if(fire_stacks <= 0)
				ExtinguishMob()
				return
			if(fire_stacks > FIRE_MAX_STACKS)
				fire_stacks = FIRE_MAX_STACKS //Hardcap to prevent gamers from applying 300 firestacks to a mob or player. That way people dont burn for all eternity.
			adjustFireLoss(20/(1+(NUM_E**(-0.25*(fire_stacks-10))))) //Logistic function A/(1+(e^(b*(x-y))) --> A the maximum number of burn you can take b the steepness of the curve y the point of inversion and x the number of firestacks. This results in that you may try to go above 30 firestacks but you still 'only' take 20 fire damage per cycle. Who would have thought that math learned 10 years ago is useful.
			if(prob(40) && fire_stacks > 0) //over time the fire will slowly burn itself out. This is meant to be decently slow so as to not make fire much less dangerous as its purpose is to prevent issues when mobs hit tens of thousands of fireloss. Irkalla edit: I upped the loss chance to 40 so its less feeling like you got napalmed when you just set your coat on fire or something. Fire will still proc wounds and infections. It just wont turbokill you unless you are in an inferno unprotected
				adjust_fire_stacks(-1)
			if(fire_stacks > 26)
				adjust_fire_stacks(-1) //This is to simulate some processes that happen during incineration namely sintering and carbonization. Skin is porous. If something is heated pores grow and fuse and thus the surface area decreases. Carbonized skin is far less reactive than uncarbonized. So we have a decrease in surface area and a decrease in reactivity thus it gets harder to be incinerated. Very gamy explanation but thats the gist of it.
			if(fire_stacks <= 0)
				ExtinguishMob()

/mob/living/fire_act()
	adjust_fire_stacks(2)
	IgniteMob()

/mob/living/proc/get_cold_protection()
	return 0

/mob/living/proc/get_heat_protection()
	return 0

//Finds the effective temperature that the mob is burning at.
/mob/living/proc/fire_burn_temperature()
	if (fire_stacks <= 0)
		return FALSE

	//Scale quadratically so that single digit numbers of fire stacks don't burn ridiculously hot.
	//lower limit of 700 K, same as matches and roughly the temperature of a cool flame.
	return FIRESTACKS_TEMP_CONV(fire_stacks)

/mob/living/proc/reagent_permeability()
	return 1

/mob/living/proc/handle_actions()
	//Pretty bad, i'd use picked/dropped instead but the parent calls in these are nonexistent
	for(var/datum/action/A in actions)
		if(A.CheckRemoval(src))
			A.Remove(src)
	for(var/obj/item/I in src)
		if(I.action_button_name)
			if(!I.action)
				if(I.action_button_is_hands_free)
					I.action = new/datum/action/item_action/hands_free
				else
					I.action = new/datum/action/item_action
				I.action.name = I.action_button_name
				I.action.target = I
				if(I.action_button_proc)
					I.action.action_type = AB_ITEM_PROC
					I.action.procname = I.action_button_proc
					if(I.action_button_arguments)
						I.action.arguments = I.action_button_arguments
			I.action.Grant(src)
	return
/*
/mob/living/update_action_buttons()
	if(!hud_used) return
	if(!client) return

	//if(hud_used.hud_shown != 1)	//Hud toggled to minimal
	//	return

	//client.screen -= hud_used.hide_actions_toggle
	for(var/datum/action/A in actions)
		if(A.button)
			client.screen -= A.button

	/*if(hud_used.action_buttons_hidden)
		if(!hud_used.hide_actions_toggle)
			hud_used.hide_actions_toggle = new(hud_used)
			hud_used.hide_actions_toggle.UpdateIcon()

		if(!hud_used.hide_actions_toggle.moved)
			hud_used.hide_actions_toggle.screen_loc = hud_used.ButtonNumberToScreenCoords(1)
			//hud_used.SetButtonCoords(hud_used.hide_actions_toggle,1)

		client.screen += hud_used.hide_actions_toggle
		return
*/
	var/button_number = 0
	for(var/datum/action/A in actions)
		button_number++
		if(A.button == null)
			var/obj/screen/movable/action_button/N = new(hud_used)
			N.owner = A
			A.button = N

		var/obj/screen/movable/action_button/B = A.button

		B.UpdateIcon()

//		B.name = A.UpdateName() /// TODO : NEEDS FIXING !!!!

		client.screen += B

		if(!B.moved)
			B.screen_loc = hud_used.ButtonNumberToScreenCoords(button_number)
			//hud_used.SetButtonCoords(B,button_number)

//	if(button_number > 0)
		/*if(!hud_used.hide_actions_toggle)
			hud_used.hide_actions_toggle = new(hud_used)
			hud_used.hide_actions_toggle.InitialiseIcon(src)
		if(!hud_used.hide_actions_toggle.moved)
			hud_used.hide_actions_toggle.screen_loc = hud_used.ButtonNumberToScreenCoords(button_number+1)
			//hud_used.SetButtonCoords(hud_used.hide_actions_toggle,button_number+1)
		client.screen += hud_used.hide_actions_toggle*/
*/
