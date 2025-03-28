/obj/item/gun/projectile/boltgun/zatvor
	name = "homemade \"Zatvor\" bolt action rifle"
	desc = "A cruel combination of an AK-pattern rifle and a bolt-action rifle. Chambered in 7.62mm."
	icon = 'icons/obj/guns/projectile/zatvor.dmi'
	icon_state = "zatvor"
	item_state = "zatvor"
	fire_sound = 'sound/weapons/guns/fire/ak.ogg'
	w_class = ITEM_SIZE_NORMAL
	force = WEAPON_FORCE_NORMAL
	caliber = CAL_RIFLE
	max_shells = 20
	damage_multiplier = 1.2
	penetration_multiplier  = 1.0
	slot_flags = SLOT_BELT|SLOT_BACK
	init_recoil = HMG_RECOIL(0.6)
	price_tag = 500
	matter = list(MATERIAL_PLASTEEL = 5, MATERIAL_STEEL = 20, MATERIAL_WOOD = 5)
	origin_tech = list(TECH_COMBAT = 5, TECH_MATERIAL = 2, TECH_ILLEGAL = 3)
	saw_off = FALSE
	serial_type = "INDEX"
	serial_shown = FALSE
