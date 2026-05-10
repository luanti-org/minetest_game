-- bones/init.lua

-- Minetest Game mod: bones
-- See README.txt for licensing and other information.

-- Load support for MT game translation.
local S = core.get_translator("bones")

bones = {}

local function is_owner(pos, name)
	local owner = core.get_meta(pos):get_string("owner")
	if owner == "" or owner == name or core.check_player_privs(name, "protection_bypass") then
		return true
	end
	return false
end

local function drop(pos, itemstack)
	local obj = core.add_item(pos, itemstack:take_item(itemstack:get_count()))
	if obj then
		obj:set_velocity({
			x = math.random(-10, 10) / 9,
			y = 5,
			z = math.random(-10, 10) / 9,
		})
	end
end

local function drop_contents(pos)
	local inv = core.get_meta(pos):get_inventory()

	for i = 1, inv:get_size("main") do
		local stk = inv:get_stack("main", i)
		drop(pos, stk)
	end
	core.remove_node(pos)
end

local bones_formspec =
	"size[8,9]" ..
	"list[current_name;main;0,0.3;8,4;]" ..
	"list[current_player;main;0,4.85;8,1;]" ..
	"list[current_player;main;0,6.08;8,3;8]" ..
	"listring[current_name;main]" ..
	"listring[current_player;main]" ..
	default.get_hotbar_bg(0,4.85)

local share_bones_time = tonumber(core.settings:get("share_bones_time")) or 1200
local share_bones_time_early = tonumber(core.settings:get("share_bones_time_early")) or share_bones_time / 4

local bones_def = {
	description = S("Bones"),
	tiles = {
		"bones_top.png^[transform2",
		"bones_bottom.png",
		"bones_side.png",
		"bones_side.png",
		"bones_rear.png",
		"bones_front.png"
	},
	paramtype2 = "facedir",
	groups = {dig_immediate = 2},
	sounds = default.node_sound_gravel_defaults(),

	can_dig = function(pos, player)
		local inv = core.get_meta(pos):get_inventory()
		local name = ""
		if player then
			name = player:get_player_name()
		end
		return is_owner(pos, name) and inv:is_empty("main")
	end,

	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		if is_owner(pos, player:get_player_name()) then
			return count
		end
		return 0
	end,

	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		return 0
	end,

	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		if is_owner(pos, player:get_player_name()) then
			return stack:get_count()
		end
		return 0
	end,

	on_metadata_inventory_take = function(pos, listname, index, stack, player)
		local meta = core.get_meta(pos)
		if meta:get_inventory():is_empty("main") then
			local inv = player:get_inventory()
			if inv:room_for_item("main", {name = "bones:bones"}) then
				inv:add_item("main", {name = "bones:bones"})
			else
				core.add_item(pos, "bones:bones")
			end
			core.remove_node(pos)
		end
	end,

	on_punch = function(pos, node, player)
		if not is_owner(pos, player:get_player_name()) then
			return
		end

		if not player:is_player() then
			drop_contents(pos)
			return
		end

		if core.get_meta(pos):get_string("infotext") == "" then
			return
		end

		local inv = core.get_meta(pos):get_inventory()
		local player_inv = player:get_inventory()
		local has_space = true

		for i = 1, inv:get_size("main") do
			local stk = inv:get_stack("main", i)
			if player_inv:room_for_item("main", stk) then
				inv:set_stack("main", i, nil)
				player_inv:add_item("main", stk)
			else
				has_space = false
				break
			end
		end

		-- remove bones if player emptied them
		if has_space then
			if player_inv:room_for_item("main", {name = "bones:bones"}) then
				player_inv:add_item("main", {name = "bones:bones"})
			else
				core.add_item(pos,"bones:bones")
			end
			core.remove_node(pos)
		end
	end,

	on_timer = function(pos, elapsed)
		local meta = core.get_meta(pos)
		local time = meta:get_int("time") + elapsed
		if time >= share_bones_time then
			meta:set_string("infotext", S("@1's old bones", meta:get_string("owner")))
			meta:set_string("owner", "")
		else
			meta:set_int("time", time)
			return true
		end
	end,
	on_blast = function(pos)
	end,
}

default.set_inventory_action_loggers(bones_def, "bones")

core.register_node("bones:bones", bones_def)

local function may_replace(pos, player)
	local node_name = core.get_node(pos).name
	local node_definition = core.registered_nodes[node_name]

	-- if the node is unknown, we return false
	if not node_definition then
		return false
	end

	-- allow replacing air
	if node_name == "air" then
		return true
	end

	-- don't replace nodes inside protections
	if core.is_protected(pos, player:get_player_name()) then
		return false
	end

	-- allow replacing liquids
	if node_definition.liquidtype ~= "none" then
		return true
	end

	-- don't replace filled chests and other nodes that don't allow it
	local can_dig_func = node_definition.can_dig
	if can_dig_func and not can_dig_func(pos, player) then
		return false
	end

	-- default to each nodes buildable_to; if a placed block would replace it, why shouldn't bones?
	-- flowers being squished by bones are more realistical than a squished stone, too
	return node_definition.buildable_to
end

local player_inventory_lists = { "main", "craft" }
bones.player_inventory_lists = player_inventory_lists

local function is_all_empty(player_inv)
	for _, list_name in ipairs(player_inventory_lists) do
		if not player_inv:is_empty(list_name) then
			return false
		end
	end
	return true
end

core.register_on_dieplayer(function(player)
	local bones_mode = core.settings:get("bones_mode") or "bones"
	if bones_mode ~= "bones" and bones_mode ~= "drop" and bones_mode ~= "keep" then
		bones_mode = "bones"
	end

	local bones_position_message = core.settings:get_bool("bones_position_message") == true
	local player_name = player:get_player_name()
	local pos = vector.round(player:get_pos())
	local pos_string = core.pos_to_string(pos)

	-- return if keep inventory set or in creative mode
	if bones_mode == "keep" or core.is_creative_enabled(player_name) then
		core.log("action", player_name .. " dies at " .. pos_string ..
			". No bones placed")
		if bones_position_message then
			core.chat_send_player(player_name, S("@1 died at @2.", player_name, pos_string))
		end
		return
	end

	local player_inv = player:get_inventory()
	if is_all_empty(player_inv) then
		core.log("action", player_name .. " dies at " .. pos_string ..
			". No bones placed")
		if bones_position_message then
			core.chat_send_player(player_name, S("@1 died at @2.", player_name, pos_string))
		end
		return
	end

	-- check if it's possible to place bones, if not find space near player
	if bones_mode == "bones" and not may_replace(pos, player) then
		local air = core.find_node_near(pos, 1, {"air"})
		if air then
			pos = air
		else
			bones_mode = "drop"
		end
	end

	if bones_mode == "drop" then
		for _, list_name in ipairs(player_inventory_lists) do
			for i = 1, player_inv:get_size(list_name) do
				drop(pos, player_inv:get_stack(list_name, i))
			end
			player_inv:set_list(list_name, {})
		end
		drop(pos, ItemStack("bones:bones"))
		core.log("action", player_name .. " dies at " .. pos_string ..
			". Inventory dropped")
		if bones_position_message then
			core.chat_send_player(player_name, S("@1 died at @2, and dropped their inventory.", player_name, pos_string))
		end
		return
	end

	local param2 = core.dir_to_facedir(player:get_look_dir())
	core.set_node(pos, {name = "bones:bones", param2 = param2})

	core.log("action", player_name .. " dies at " .. pos_string ..
		". Bones placed")
	if bones_position_message then
		core.chat_send_player(player_name, S("@1 died at @2, and bones were placed.", player_name, pos_string))
	end

	local meta = core.get_meta(pos)
	local inv = meta:get_inventory()
	inv:set_size("main", 8 * 4)

	for _, list_name in ipairs(player_inventory_lists) do
		for i = 1, player_inv:get_size(list_name) do
			local stack = player_inv:get_stack(list_name, i)
			if inv:room_for_item("main", stack) then
				inv:add_item("main", stack)
			else -- no space left
				drop(pos, stack)
			end
		end
		player_inv:set_list(list_name, {})
	end

	meta:set_string("formspec", bones_formspec)
	meta:set_string("owner", player_name)

	if share_bones_time ~= 0 then
		meta:set_string("infotext", S("@1's fresh bones", player_name))

		if share_bones_time_early == 0 or not core.is_protected(pos, player_name) then
			meta:set_int("time", 0)
		else
			meta:set_int("time", (share_bones_time - share_bones_time_early))
		end

		core.get_node_timer(pos):start(10)
	else
		meta:set_string("infotext", S("@1's bones", player_name))
	end
end)
