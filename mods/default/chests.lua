default.chest = {}
default.chest.registered_sizes = {}

-- support for MT game translation.
local S = default.get_translator

-- Default inventory size (columns x rows)
local DEFAULT_INV_SIZE = {x = 8, y = 4}

-- Spacing constants (in real_coordinates units)
local SLOT_SIZE = 1.25
local PADDING = 0.375
local CHEST_PLAYER_GAP = 0.5
local HOTBAR_MAIN_GAP = 0.25

-- Validates inv_size and returns a valid {x, y} table or falls back to
-- DEFAULT_INV_SIZE with a warning log message.
local function validate_inv_size(inv_size, chest_name)
	if inv_size == nil then
		return DEFAULT_INV_SIZE
	end
	assert(type(inv_size) == "table")
	local x, y = inv_size.x, inv_size.y
	assert(x > 0 and y > 0)
	assert(x == math.floor(x) and y == math.floor(y), "Expected whole numbers")

	if x > 16 or y > 16 then
		core.log("warning", "[default] Chest '" .. chest_name ..
			"': inv_size values must be 1-16, got {x=" .. x .. ", y=" .. y ..
			"}. Using default 8x4.")
		return DEFAULT_INV_SIZE
	end
	return {x = x, y = y}
end

function default.chest.get_chest_formspec(pos)
	local spos = pos.x .. "," .. pos.y .. "," .. pos.z
	local node_name = minetest.get_node(pos).name:gsub("_open$", "")
	local inv_size = default.chest.registered_sizes[node_name] or DEFAULT_INV_SIZE

	local chest_w = inv_size.x * SLOT_SIZE
	local chest_h = inv_size.y * SLOT_SIZE
	local player_w = 8 * SLOT_SIZE
	local player_h = 1 * SLOT_SIZE + HOTBAR_MAIN_GAP + 3 * SLOT_SIZE

	local inner_w = math.max(chest_w, player_w)
	local inner_h = chest_h + CHEST_PLAYER_GAP + player_h

	local form_w = inner_w + 2 * PADDING
	local form_h = inner_h + 2 * PADDING

	-- Centering offsets
	local chest_x = PADDING + (inner_w - chest_w) / 2
	local chest_y = PADDING
	local player_x = PADDING + (inner_w - player_w) / 2
	local hotbar_y = PADDING + chest_h + CHEST_PLAYER_GAP
	local main_y = hotbar_y + SLOT_SIZE + HOTBAR_MAIN_GAP

	return "formspec_version[2]" ..
		"size[" .. form_w .. "," .. form_h .. "]" ..
		"real_coordinates[true]" ..
		"list[nodemeta:" .. spos .. ";main;" .. chest_x .. "," .. chest_y ..
			";" .. inv_size.x .. "," .. inv_size.y .. ";]" ..
		"list[current_player;main;" .. player_x .. "," .. hotbar_y .. ";8,1;]" ..
		"list[current_player;main;" .. player_x .. "," .. main_y .. ";8,3;8]" ..
		"listring[nodemeta:" .. spos .. ";main]" ..
		"listring[current_player;main]"
end

function default.chest.chest_lid_obstructed(pos)
	local above = {x = pos.x, y = pos.y + 1, z = pos.z}
	local def = minetest.registered_nodes[minetest.get_node(above).name]
	-- allow ladders, signs, wallmounted things and torches to not obstruct
	if def and
			(def.drawtype == "airlike" or
			def.drawtype == "signlike" or
			def.drawtype == "torchlike" or
			(def.drawtype == "nodebox" and def.paramtype2 == "wallmounted")) then
		return false
	end
	return true
end

function default.chest.chest_lid_close(pn)
	local chest_open_info = default.chest.open_chests[pn]
	local pos = chest_open_info.pos
	local sound = chest_open_info.sound
	local swap = chest_open_info.swap

	default.chest.open_chests[pn] = nil
	for k, v in pairs(default.chest.open_chests) do
		if vector.equals(v.pos, pos) then
			-- another player is also looking at the chest
			return true
		end
	end

	local node = minetest.get_node(pos)
	minetest.after(0.2, function()
		local current_node = minetest.get_node(pos)
		if current_node.name ~= swap .. "_open" then
			-- the chest has already been replaced, don't try to replace what's there.
			return
		end
		minetest.swap_node(pos, {name = swap, param2 = node.param2})
		minetest.sound_play(sound, {gain = 0.3, pos = pos,
			max_hear_distance = 10}, true)
	end)
end

default.chest.open_chests = {}

minetest.register_on_player_receive_fields(function(player, formname, fields)
	local pn = player:get_player_name()

	if formname ~= "default:chest" then
		if default.chest.open_chests[pn] then
			default.chest.chest_lid_close(pn)
		end

		return
	end

	if not (fields.quit and default.chest.open_chests[pn]) then
		return
	end

	default.chest.chest_lid_close(pn)

	return true
end)

minetest.register_on_leaveplayer(function(player)
	local pn = player:get_player_name()
	if default.chest.open_chests[pn] then
		default.chest.chest_lid_close(pn)
	end
end)

function default.chest.register_chest(prefixed_name, d)
	local name = prefixed_name:sub(1,1) == ':' and prefixed_name:sub(2,-1) or prefixed_name
	local def = table.copy(d)
	local inv_size = validate_inv_size(def.inv_size, name)
	def.inv_size = nil
	default.chest.registered_sizes[name] = inv_size
	def.drawtype = "mesh"
	def.visual = "mesh"
	def.paramtype = "light"
	def.paramtype2 = "facedir"
	def.legacy_facedir_simple = true
	def.is_ground_content = false

	if def.protected then
		def.on_construct = function(pos)
			local meta = minetest.get_meta(pos)
			meta:set_string("infotext", S("Locked Chest"))
			meta:set_string("owner", "")
			local inv = meta:get_inventory()
			inv:set_size("main", inv_size.x * inv_size.y)
		end
		def.after_place_node = function(pos, placer)
			local meta = minetest.get_meta(pos)
			meta:set_string("owner", placer:get_player_name() or "")
			meta:set_string("infotext", S("Locked Chest (owned by @1)", meta:get_string("owner")))
		end
		def.can_dig = function(pos,player)
			local meta = minetest.get_meta(pos);
			local inv = meta:get_inventory()
			return inv:is_empty("main") and
					default.can_interact_with_node(player, pos)
		end
		def.allow_metadata_inventory_move = function(pos, from_list, from_index,
				to_list, to_index, count, player)
			if not default.can_interact_with_node(player, pos) then
				return 0
			end
			return count
		end
		def.allow_metadata_inventory_put = function(pos, listname, index, stack, player)
			if not default.can_interact_with_node(player, pos) then
				return 0
			end
			return stack:get_count()
		end
		def.allow_metadata_inventory_take = function(pos, listname, index, stack, player)
			if not default.can_interact_with_node(player, pos) then
				return 0
			end
			return stack:get_count()
		end
		def.on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
			if not default.can_interact_with_node(clicker, pos) then
				return itemstack
			end

			local cn = clicker:get_player_name()

			if default.chest.open_chests[cn] then
				default.chest.chest_lid_close(cn)
			end

			minetest.sound_play(def.sound_open, {gain = 0.3,
					pos = pos, max_hear_distance = 10}, true)
			if not default.chest.chest_lid_obstructed(pos) then
				minetest.swap_node(pos,
						{ name = name .. "_open",
						param2 = node.param2 })
			end
			minetest.after(0.2, minetest.show_formspec, cn,
					"default:chest", default.chest.get_chest_formspec(pos))
			default.chest.open_chests[cn] = { pos = pos,
					sound = def.sound_close, swap = name }
		end
		def.on_blast = function() end
		def.on_key_use = function(pos, player)
			local secret = minetest.get_meta(pos):get_string("key_lock_secret")
			local itemstack = player:get_wielded_item()
			local key_meta = itemstack:get_meta()

			if itemstack:get_meta():get_string("") == "" then
				return
			end

			if key_meta:get_string("secret") == "" then
				key_meta:set_string("secret", minetest.parse_json(itemstack:get_meta():get_string("")).secret)
				itemstack:set_metadata("")
			end

			if secret ~= key_meta:get_string("secret") then
				return
			end

			minetest.show_formspec(
				player:get_player_name(),
				"default:chest_locked",
				default.chest.get_chest_formspec(pos)
			)
		end
		def.on_skeleton_key_use = function(pos, player, newsecret)
			local meta = minetest.get_meta(pos)
			local owner = meta:get_string("owner")
			local pn = player:get_player_name()

			-- verify placer is owner of lockable chest
			if owner ~= pn then
				minetest.record_protection_violation(pos, pn)
				minetest.chat_send_player(pn, S("You do not own this chest."))
				return nil
			end

			local secret = meta:get_string("key_lock_secret")
			if secret == "" then
				secret = newsecret
				meta:set_string("key_lock_secret", secret)
			end

			return secret, S("a locked chest"), owner
		end
	else
		def.on_construct = function(pos)
			local meta = minetest.get_meta(pos)
			meta:set_string("infotext", S("Chest"))
			local inv = meta:get_inventory()
			inv:set_size("main", inv_size.x * inv_size.y)
		end
		def.can_dig = function(pos,player)
			local meta = minetest.get_meta(pos);
			local inv = meta:get_inventory()
			return inv:is_empty("main")
		end
		def.on_rightclick = function(pos, node, clicker)
			local cn = clicker:get_player_name()

			if default.chest.open_chests[cn] then
				default.chest.chest_lid_close(cn)
			end

			minetest.sound_play(def.sound_open, {gain = 0.3, pos = pos,
					max_hear_distance = 10}, true)
			if not default.chest.chest_lid_obstructed(pos) then
				minetest.swap_node(pos, {
						name = name .. "_open",
						param2 = node.param2 })
			end
			minetest.after(0.2, minetest.show_formspec,
					cn,
					"default:chest", default.chest.get_chest_formspec(pos))
			default.chest.open_chests[cn] = { pos = pos,
					sound = def.sound_close, swap = name }
		end
		def.on_blast = function(pos)
			local drops = {}
			default.get_inventory_drops(pos, "main", drops)
			drops[#drops+1] = name
			minetest.remove_node(pos)
			return drops
		end
	end

	default.set_inventory_action_loggers(def, "chest")

	local def_opened = table.copy(def)
	local def_closed = table.copy(def)

	def_opened.mesh = "chest_open.obj"
	for i = 1, #def_opened.tiles do
		if type(def_opened.tiles[i]) == "string" then
			def_opened.tiles[i] = {name = def_opened.tiles[i], backface_culling = true}
		elseif def_opened.tiles[i].backface_culling == nil then
			def_opened.tiles[i].backface_culling = true
		end
	end
	def_opened.drop = name
	def_opened.groups.not_in_creative_inventory = 1
	def_opened.selection_box = {
		type = "fixed",
		fixed = { -1/2, -1/2, -1/2, 1/2, 3/16, 1/2 },
	}
	def_opened.can_dig = function()
		return false
	end
	def_opened.on_blast = function() end

	def_closed.mesh = nil
	def_closed.drawtype = nil
	def_closed.tiles[6] = def.tiles[5] -- swap textures around for "normal"
	def_closed.tiles[5] = def.tiles[3] -- drawtype to make them match the mesh
	def_closed.tiles[3] = def.tiles[3].."^[transformFX"

	minetest.register_node(prefixed_name, def_closed)
	minetest.register_node(prefixed_name .. "_open", def_opened)

	-- Convert old chests to this new variant.
	-- Clears stored formspec so the dynamic formspec generation (with
	-- configurable inv_size) is used on next open. Existing inventory
	-- items are preserved; no resizing is performed.
	if name == "default:chest" or name == "default:chest_locked" then
		minetest.register_lbm({
			label = "update chests to opening chests",
			name = "default:upgrade_" .. name:sub(9,-1) .. "_v2",
			nodenames = {name},
			action = function(pos, node)
				local meta = minetest.get_meta(pos)
				meta:set_string("formspec", "")
				local inv = meta:get_inventory()
				local list = inv:get_list("default:chest")
				if list then
					inv:set_size("main", 8*4)
					inv:set_list("main", list)
					inv:set_list("default:chest", nil)
				end
			end
		})
	end

	-- close opened chests on load
	local modname, chestname = prefixed_name:match("^(:?.-):(.*)$")
	minetest.register_lbm({
		label = "close opened chests on load",
		name = modname .. ":close_" .. chestname .. "_open",
		nodenames = {prefixed_name .. "_open"},
		run_at_every_load = true,
		action = function(pos, node)
			node.name = prefixed_name
			minetest.swap_node(pos, node)
		end
	})
end

default.chest.register_chest("default:chest", {
	description = S("Chest"),
	tiles = {
		"default_chest_top.png",
		"default_chest_top.png",
		"default_chest_side.png",
		"default_chest_side.png",
		"default_chest_front.png",
		"default_chest_inside.png"
	},
	sounds = default.node_sound_wood_defaults(),
	sound_open = "default_chest_open",
	sound_close = "default_chest_close",
	groups = {choppy = 2, oddly_breakable_by_hand = 2},
})

default.chest.register_chest("default:chest_locked", {
	description = S("Locked Chest"),
	tiles = {
		"default_chest_top.png",
		"default_chest_top.png",
		"default_chest_side.png",
		"default_chest_side.png",
		"default_chest_lock.png",
		"default_chest_inside.png"
	},
	sounds = default.node_sound_wood_defaults(),
	sound_open = "default_chest_open",
	sound_close = "default_chest_close",
	groups = {choppy = 2, oddly_breakable_by_hand = 2},
	protected = true,
})

minetest.register_craft({
	output = "default:chest",
	recipe = {
		{"group:wood", "group:wood", "group:wood"},
		{"group:wood", "", "group:wood"},
		{"group:wood", "group:wood", "group:wood"},
	}
})

minetest.register_craft({
	output = "default:chest_locked",
	recipe = {
		{"group:wood", "group:wood", "group:wood"},
		{"group:wood", "default:steel_ingot", "group:wood"},
		{"group:wood", "group:wood", "group:wood"},
	}
})

minetest.register_craft( {
	type = "shapeless",
	output = "default:chest_locked",
	recipe = {"default:chest", "default:steel_ingot"},
})

minetest.register_craft({
	type = "fuel",
	recipe = "default:chest",
	burntime = 30,
})

minetest.register_craft({
	type = "fuel",
	recipe = "default:chest_locked",
	burntime = 30,
})
