/obj/item/gun/projectile/automatic/riot_autoshotgun
	name = "\"State\" riot shotgun"
	desc = "An unorthodox top-loading semi-automatic riot shotgun. Chambered in 20mm."
	icon = 'icons/obj/guns/projectile/milshotgun.dmi'
	icon_state = "cshotgun"
	item_state = "cshotgun"
	max_shells = 8
	w_class = ITEM_SIZE_HUGE
	force = WEAPON_FORCE_PAINFUL
	flags = CONDUCT
	slot_flags = SLOT_BACK
	caliber = CAL_SHOTGUN
	origin_tech = list(TECH_COMBAT = 4, TECH_MATERIAL = 2)
	load_method = SINGLE_CASING|SPEEDLOADER
	ammo_type = /obj/item/ammo_casing/shotgun/beanbag
	handle_casings = EJECT_CASINGS
	fire_sound = 'sound/weapons/guns/fire/shotgun_combat.ogg'
	bulletinsert_sound 	= 'sound/weapons/guns/interact/shotgun_insert.ogg'
	matter = list(MATERIAL_PLASTEEL = 20, MATERIAL_PLASTIC = 10)
	price_tag = 1250
	damage_multiplier = 1.2
	init_recoil = RIFLE_RECOIL(1.3)
	gun_tags = list(GUN_PROJECTILE, GUN_INTERNAL_MAG)

	init_firemodes = list(
		list(mode_name="semiauto", mode_desc="Shoot once per pull after chambering", burst=1, fire_delay=5, move_delay=null, icon="semi")
		)
	serial_type = "SD GmbH"

	wield_delay = 0.9 SECOND
	wield_delay_factor = 0.4 // 40 vig
	gun_parts = list(/obj/item/part/gun/frame/opshot = 1, /obj/item/part/gun/grip/rubber = 1, /obj/item/part/gun/mechanism/shotgun = 1, /obj/item/part/gun/barrel/shotgun = 1)

/obj/item/gun/projectile/automatic/riot_autoshotgun/robo
	name = "integrated \"State\" riot shotgun"
	desc = "A modified arm mounted riot shotgun. Chambered in 20mm."
	icon = 'icons/obj/robot_items.dmi'
	icon_state = "riot_shotgun"
	item_state = "riot_shotgun"
	damage_multiplier = 0.7
	init_recoil = RIFLE_RECOIL(0)
	max_shells = 6
	load_method = SINGLE_CASING|SPEEDLOADER

/obj/item/gun/projectile/automatic/riot_autoshotgun/robo/single_shot
	name = "integrated single barrel shotgun"
	desc = "A auto ejecting single barrel shotgun for mining borgs to handle pesky critters in the underground."
	icon_state = "miner_shotgun"
	item_state = "miner_shotgun"
	damage_multiplier = 1
	max_shells = 1

/obj/item/gun/projectile/automatic/riot_autoshotgun/opshot
	name = "\"Operator\" combat shotgun"
	desc = "A modified in-colony State top-loading riot shotgun. Chambered in 20mm, fitted with aftermarket parts."
	icon = 'icons/obj/guns/projectile/operator.dmi'
	icon_state = "operator"
	item_state = "oporator"
	fire_sound = 'sound/weapons/guns/fire/regulator.ogg'
	w_class = ITEM_SIZE_BULKY
	origin_tech = list(TECH_COMBAT = 7, TECH_MATERIAL = 4)
	max_shells = 7
	ammo_type = /obj/item/ammo_casing/shotgun
	matter = list(MATERIAL_PLASTEEL = 25, MATERIAL_PLASTIC = 12)
	price_tag = 1000
	damage_multiplier = 0.8
	penetration_multiplier = 1
	zoom_factors = list(0.2)
	init_recoil = RIFLE_RECOIL(1.4)
	folding_stock = TRUE //we can fold our stock
	can_dual = FALSE

	wield_delay = 0.8 SECOND
	wield_delay_factor = 0.4 // 40 vig , after all its designed for CQC
	gun_parts = list(/obj/item/part/gun/frame/opshot = 1, /obj/item/part/gun/grip/black = 1, /obj/item/part/gun/mechanism/shotgun = 1, /obj/item/part/gun/barrel/shotgun = 1)

/obj/item/part/gun/frame/opshot
	name = "State frame"
	desc = "A State riot shotgun frame."
	icon_state = "frame_gladstone"
	result = /obj/item/gun/projectile/automatic/riot_autoshotgun/opshot
	gripvars = list(/obj/item/part/gun/grip/black, /obj/item/part/gun/grip/rubber)
	mechanismvar = /obj/item/part/gun/mechanism/shotgun
	barrelvars = list(/obj/item/part/gun/barrel/shotgun)
	resultvars = list(/obj/item/gun/projectile/automatic/riot_autoshotgun/opshot, /obj/item/gun/projectile/automatic/riot_autoshotgun)

/obj/item/gun/projectile/automatic/riot_autoshotgun/opshot/update_icon()
	..()
	var/iconstring = initial(icon_state)
	var/itemstring = ""

	if(!folded)
		iconstring += "_stock"

	if(wielded)
		itemstring += "_doble"


	icon_state = iconstring
	set_item_state(itemstring)
