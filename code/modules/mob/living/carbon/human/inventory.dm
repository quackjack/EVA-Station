/mob/living/carbon/human/can_equip(obj/item/I, slot, disable_warning = FALSE, bypass_equip_delay_self = FALSE, clothing_check = FALSE, list/return_warning)
	return dna.species.can_equip(I, slot, disable_warning, src, bypass_equip_delay_self, clothing_check, return_warning)

/**
 * Used to return a list of equipped items on a human mob; does not include held items (use get_all_gear)
 *
 * Argument(s):
 * * Optional - include_pockets (TRUE/FALSE), whether or not to include the pockets and suit storage in the returned list
 */

/mob/living/carbon/human/get_equipped_items(include_pockets = FALSE)
	var/list/items = ..()
	if(!include_pockets)
		items -= list(l_store, r_store, s_store)
	return items

// Return the item currently in the slot ID
/mob/living/carbon/human/get_item_by_slot(slot_id)
	switch(slot_id)
		if(SLOT_BACK)
			return back
		if(SLOT_WEAR_MASK)
			return wear_mask
		if(SLOT_NECK)
			return wear_neck
		if(SLOT_HANDCUFFED)
			return handcuffed
		if(SLOT_LEGCUFFED)
			return legcuffed
		if(SLOT_BELT)
			return belt
		if(SLOT_WEAR_ID)
			return wear_id
		if(SLOT_EARS)
			return ears
		if(SLOT_GLASSES)
			return glasses
		if(SLOT_GLOVES)
			return gloves
		if(SLOT_HEAD)
			return head
		if(SLOT_SHOES)
			return shoes
		if(SLOT_WEAR_SUIT)
			return wear_suit
		if(SLOT_W_UNIFORM)
			return w_uniform
		if(SLOT_L_STORE)
			return l_store
		if(SLOT_R_STORE)
			return r_store
		if(SLOT_S_STORE)
			return s_store
	return null

/mob/living/carbon/human/proc/get_all_slots()
	. = get_head_slots() | get_body_slots()

/mob/living/carbon/human/proc/get_body_slots()
	return list(
		back,
		s_store,
		handcuffed,
		legcuffed,
		wear_suit,
		gloves,
		shoes,
		belt,
		wear_id,
		l_store,
		r_store,
		w_uniform
		)

/mob/living/carbon/human/proc/get_head_slots()
	return list(
		head,
		wear_mask,
		wear_neck,
		glasses,
		ears,
		)

/mob/living/carbon/human/proc/get_storage_slots()
	return list(
		back,
		belt,
		l_store,
		r_store,
		s_store,
		)

//This is an UNSAFE proc. Use mob_can_equip() before calling this one! Or rather use equip_to_slot_if_possible() or advanced_equip_to_slot_if_possible()
/mob/living/carbon/human/equip_to_slot(obj/item/I, slot)
	. = ..()
	if(!.) //a check failed or the item has already found its slot
		return

	var/not_handled = FALSE //Added in case we make this type path deeper one day
	switch(slot)
		if(SLOT_BELT)
			belt = I
			update_inv_belt()
		if(SLOT_WEAR_ID)
			wear_id = I
			sec_hud_set_ID()
			update_inv_wear_id()
		if(SLOT_EARS)
			ears = I
			update_inv_ears()
		if(SLOT_GLASSES)
			glasses = I
			var/obj/item/clothing/glasses/G = I
			if(G.glass_colour_type)
				update_glasses_color(G, 1)
			if(G.tint)
				update_tint()
			if(G.vision_correction)
				clear_fullscreen("nearsighted")
				clear_fullscreen("eye_damage")
			if(G.vision_flags || G.darkness_view || G.invis_override || G.invis_view || !isnull(G.lighting_alpha))
				update_sight()
			update_inv_glasses()
		if(SLOT_GLOVES)
			gloves = I
			update_inv_gloves()
		if(SLOT_SHOES)
			shoes = I
			update_inv_shoes()
		if(SLOT_WEAR_SUIT)
			wear_suit = I
			if(I.flags_inv & HIDEJUMPSUIT)
				update_inv_w_uniform()
			if(wear_suit.breakouttime) //when equipping a straightjacket
				stop_pulling() //can't pull if restrained
				update_action_buttons_icon() //certain action buttons will no longer be usable.
			update_inv_wear_suit()
		if(SLOT_W_UNIFORM)
			w_uniform = I
			update_suit_sensors()
			update_inv_w_uniform()
		if(SLOT_L_STORE)
			l_store = I
			update_inv_pockets()
		if(SLOT_R_STORE)
			r_store = I
			update_inv_pockets()
		if(SLOT_S_STORE)
			s_store = I
			update_inv_s_store()
		else
			to_chat(src, "<span class='danger'>You are trying to equip this item to an unsupported inventory slot. Report this to a coder!</span>")
			not_handled = TRUE

	//Item is handled and in slot, valid to call callback, for this proc should always be true
	if(!not_handled)
		I.equipped(src, slot)
	//update_genitals()
	return not_handled //For future deeper overrides

/mob/living/carbon/human/equipped_speed_mods()
	. = ..()
	for(var/sloties in get_all_slots() - list(l_store, r_store, s_store))
		var/obj/item/thing = sloties
		. += thing?.slowdown

/mob/living/carbon/human/doUnEquip(obj/item/I, force, newloc, no_move, invdrop = TRUE, silent = FALSE)
	var/index = get_held_index_of_item(I)
	. = ..() //See mob.dm for an explanation on this and some rage about people copypasting instead of calling ..() like they should.
	if(!. || !I)
		return
	if(index && !QDELETED(src) && dna.species.mutanthands) //hand freed, fill with claws, skip if we're getting deleted.
		put_in_hand(new dna.species.mutanthands(), index)
	if(I == wear_suit)
		if(s_store && invdrop)
			dropItemToGround(s_store, TRUE) //It makes no sense for your suit storage to stay on you if you drop your suit.
		if(wear_suit.breakouttime) //when unequipping a straightjacket
			drop_all_held_items() //suit is restraining
			update_action_buttons_icon() //certain action buttons may be usable again.
		wear_suit = null
		if(!QDELETED(src)) //no need to update we're getting deleted anyway
			if(I.flags_inv & HIDEJUMPSUIT)
				update_inv_w_uniform()
			update_inv_wear_suit()
	else if(I == w_uniform)
		if(invdrop)
			if(r_store)
				dropItemToGround(r_store, TRUE) //Again, makes sense for pockets to drop.
			if(l_store)
				dropItemToGround(l_store, TRUE)
			if(wear_id && !CHECK_BITFIELD(wear_id.item_flags, NO_UNIFORM_REQUIRED))
				dropItemToGround(wear_id)
			if(belt && !CHECK_BITFIELD(belt.item_flags, NO_UNIFORM_REQUIRED))
				dropItemToGround(belt)
		w_uniform = null
		update_suit_sensors()
		if(!QDELETED(src))
			update_inv_w_uniform()
	else if(I == gloves)
		gloves = null
		if(!QDELETED(src))
			update_inv_gloves()
	else if(I == glasses)
		glasses = null
		var/obj/item/clothing/glasses/G = I
		if(G.glass_colour_type)
			update_glasses_color(G, 0)
		if(G.tint)
			update_tint()
		if(G.vision_correction)
			if(HAS_TRAIT(src, TRAIT_NEARSIGHT))
				overlay_fullscreen("nearsighted", /obj/screen/fullscreen/impaired, 1)
		if(G.vision_flags || G.darkness_view || G.invis_override || G.invis_view || !isnull(G.lighting_alpha))
			update_sight()
		if(!QDELETED(src))
			update_inv_glasses()
	else if(I == ears)
		ears = null
		if(!QDELETED(src))
			update_inv_ears()
	else if(I == shoes)
		shoes = null
		if(!QDELETED(src))
			update_inv_shoes()
	else if(I == belt)
		belt = null
		if(!QDELETED(src))
			update_inv_belt()
	else if(I == wear_id)
		wear_id = null
		sec_hud_set_ID()
		if(!QDELETED(src))
			update_inv_wear_id()
	else if(I == r_store)
		r_store = null
		if(!QDELETED(src))
			update_inv_pockets()
	else if(I == l_store)
		l_store = null
		if(!QDELETED(src))
			update_inv_pockets()
	else if(I == s_store)
		s_store = null
		if(!QDELETED(src))
			update_inv_s_store()
	//update_genitals()

/mob/living/carbon/human/wear_mask_update(obj/item/clothing/C, toggle_off = 1)
	if((C.flags_inv & (HIDEHAIR|HIDEFACIALHAIR)) || (initial(C.flags_inv) & (HIDEHAIR|HIDEFACIALHAIR)))
		update_hair()
	if(toggle_off && internal && !getorganslot(ORGAN_SLOT_BREATHING_TUBE))
		update_internals_hud_icon(0)
		internal = null
	if(C.flags_inv & HIDEEYES)
		update_inv_glasses()
	sec_hud_set_security_status()
	..()

/mob/living/carbon/human/head_update(obj/item/I, forced)
	if((I.flags_inv & (HIDEHAIR|HIDEFACIALHAIR)) || forced)
		update_hair()
	else
		var/obj/item/clothing/C = I
		if(istype(C) && C.dynamic_hair_suffix)
			update_hair()
	if(I.flags_inv & HIDEEYES || forced)
		update_inv_glasses()
	if(I.flags_inv & HIDEEARS || forced)
		update_body()
	sec_hud_set_security_status()
	..()

/mob/living/carbon/human/proc/equipOutfit(outfit, visualsOnly = FALSE, client/preference_source)
	var/datum/outfit/O = null

	if(ispath(outfit))
		O = new outfit
	else
		O = outfit
		if(!istype(O))
			return 0
	if(!O)
		return 0

	return O.equip(src, visualsOnly, preference_source)


//delete all equipment without dropping anything
/mob/living/carbon/human/proc/delete_equipment()
	for(var/slot in get_all_slots())//order matters, dependant slots go first
		qdel(slot)
	for(var/obj/item/I in held_items)
		qdel(I)

/mob/living/carbon/human/proc/smart_equipbag() // take most recent item out of bag or place held item in bag
	if(incapacitated())
		return
	var/obj/item/thing = get_active_held_item()
	var/obj/item/equipped_back = get_item_by_slot(SLOT_BACK)
	if(!equipped_back) // We also let you equip a backpack like this
		if(!thing)
			to_chat(src, "<span class='warning'>You have no backpack to take something out of!</span>")
			return
		if(equip_to_slot_if_possible(thing, ITEM_SLOT_BACK))
			update_inv_hands()
		return
	if(!SEND_SIGNAL(equipped_back, COMSIG_CONTAINS_STORAGE)) // not a storage item
		if(!thing)
			equipped_back.attack_hand(src)
		else
			to_chat(src, "<span class='warning'>You can't fit anything in!</span>")
		return
	if(thing) // put thing in backpack
		if(!SEND_SIGNAL(equipped_back, COMSIG_TRY_STORAGE_INSERT, thing, src))
			to_chat(src, "<span class='warning'>You can't fit anything in!</span>")
		return
	if(!equipped_back.contents.len) // nothing to take out
		to_chat(src, "<span class='warning'>There's nothing in your backpack to take out!</span>")
		return
	var/obj/item/stored = equipped_back.contents[equipped_back.contents.len]
	if(!stored || stored.on_found(src))
		return
	stored.attack_hand(src) // take out thing from backpack
	return

/mob/living/carbon/human/proc/smart_equipbelt() // put held thing in belt or take most recent item out of belt
	if(incapacitated())
		return
	var/obj/item/thing = get_active_held_item()
	var/obj/item/equipped_belt = get_item_by_slot(SLOT_BELT)
	if(!equipped_belt) // We also let you equip a belt like this
		if(!thing)
			to_chat(src, "<span class='warning'>You have no belt to take something out of!</span>")
			return
		if(equip_to_slot_if_possible(thing, ITEM_SLOT_BELT))
			update_inv_hands()
		return
	if(!SEND_SIGNAL(equipped_belt, COMSIG_CONTAINS_STORAGE)) // not a storage item
		if(!thing)
			equipped_belt.attack_hand(src)
		else
			to_chat(src, "<span class='warning'>You can't fit anything in!</span>")
		return
	if(thing) // put thing in belt
		if(!SEND_SIGNAL(equipped_belt, COMSIG_TRY_STORAGE_INSERT, thing, src))
			to_chat(src, "<span class='warning'>You can't fit anything in!</span>")
		return
	if(!equipped_belt.contents.len) // nothing to take out
		to_chat(src, "<span class='warning'>There's nothing in your belt to take out!</span>")
		return
	var/obj/item/stored = equipped_belt.contents[equipped_belt.contents.len]
	if(!stored || stored.on_found(src))
		return
	stored.attack_hand(src) // take out thing from belt
	return
