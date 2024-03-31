-- bones/init.lua

-- Minetest Game mod: bones
-- See README.txt for licensing and other information.

-- Load support for MT game translation.
local S = minetest.get_translator("bones")

local bones_max_slots = tonumber(minetest.settings:get("bones_max_slots")) or 15 * 10
local min_inv_size = 4 * 8 -- display and provide at least this many slots

bones = {}

local function NS(s)
	return s
end

local function is_owner(pos, name)
	local owner = minetest.get_meta(pos):get_string("owner")
	if owner == "" or owner == name or minetest.check_player_privs(name, "protection_bypass") then
		return true
	end
	return false
end

local function appendmulti(tbl,...)
	for _, v in pairs({...}) do
		table.insert(tbl, v)
	end
end


local function drop(pos, itemstack)
	local obj = minetest.add_item(pos, itemstack:take_item(itemstack:get_count()))
	if obj then
		obj:set_velocity({
			x = math.random(-10, 10) / 9,
			y = 5,
			z = math.random(-10, 10) / 9,
		})
	end
end


local function drop_contents(pos)
	local inv = minetest.get_meta(pos):get_inventory()

	for i = 1, inv:get_size("main") do
		local stk = inv:get_stack("main", i)
		drop(pos, stk)
	end
	minetest.remove_node(pos)
end


local function get_bones_formspec_wh(cols,rows)
	return
		"size[" .. cols .. "," .. (rows + 5) .. "]" ..
		"list[current_name;main;0,0.3;" .. cols .. "," .. rows .. ";]" ..
		"list[current_player;main;" .. ((cols - 8) / 2) .. "," .. rows .. ".85;8,1;]" ..
		"list[current_player;main;".. ((cols - 8) / 2) .. "," .. (rows + 2) .. ".08;8,3;8]" ..
		"listring[current_name;main]" ..
		"listring[current_player;main]" ..
		default.get_hotbar_bg(0,4.85)
end


local function get_bones_formspec_for_size(numitems)
	local cols, rows
	local scroll=false
	if numitems <= min_inv_size then
		cols, rows = 8, 4
	else
		cols, rows = 8, math.ceil(numitems / 8)
		scroll=true
	end
	local output={}
	appendmulti(output, "size[", 8.5, ",", 9, "]")
	if scroll  then
		-- ok so I don't want to figure out the constants for (rows-delta)*multiplier so I'll let this code do it for me
		local row_05=13.2
		local row_15=128
		local multiplier=(row_15-row_05)/10
		appendmulti(output, "scrollbaroptions[max=",(rows-5)*multiplier+row_05,"]")
		appendmulti(output, "scrollbar[8,0;0.3,4.5;vertical;bones_scroll;0]")
		appendmulti(output, "scroll_container[0,0.3;10.3,4.95;bones_scroll;vertical;0.1]")
	end
	appendmulti(output, "list[current_name;main;0,0;", cols, ",", rows, ";]")
	if scroll then
		appendmulti(output, "scroll_container_end[]")
	end
	appendmulti(output, "list[current_player;main;", 0, ",", 4.75, ";8,1;]")
	appendmulti(output, "list[current_player;main;", 0, ",", 5.98, ";8,3;8]")
	appendmulti(output, "listring[current_name;main]")
	appendmulti(output, "listring[current_player;main]")
	appendmulti(output, default.get_hotbar_bg(0, 4.85))
	return table.concat(output)
end


local share_bones_time = tonumber(minetest.settings:get("share_bones_time")) or 1200
local share_bones_time_early = tonumber(minetest.settings:get("share_bones_time_early")) or share_bones_time / 4

local function find_next_empty(inv,listname,start)
	while start <= inv:get_size(listname) do
		if inv:get_stack(listname, start):get_count() == 0 then
			return start
		end
		start = start + 1
	end
	return -1
end

local function find_next_populated(inv, listname, start)
	while start <= inv:get_size(listname) do
		if inv:get_stack(listname, start):get_count() > 0 then
			return start
		end
		start = start + 1
	end
	return -1
end

-- slot reordering to make sure the first rows of the bone are always populated
local function bones_inv_reorder(meta)
	local next_empty = 1 -- there are no empty slots inside the bones before this
	local next_populated -- there are no populated slots preceded by unpopulated slots before this
	local inv = meta:get_inventory()
	next_empty = find_next_empty(inv, "main", next_empty)
	if next_empty < 0 then
		return
	end
	next_populated = find_next_populated(inv, "main", next_empty + 1)
	while next_populated > 0 do
		local stack = inv:get_stack("main", next_populated)
		inv:set_stack("main", next_populated, ItemStack())
		inv:set_stack("main", next_empty, stack)
		next_empty = find_next_empty(inv, "main", next_empty + 1)
		next_populated = find_next_populated(inv, "main", next_populated + 1)
	end
end

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
		local inv = minetest.get_meta(pos):get_inventory()
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
		local meta = minetest.get_meta(pos)
		if meta:get_inventory():is_empty("main") then
			local inv = player:get_inventory()
			if inv:room_for_item("main", {name = "bones:bones"}) then
				inv:add_item("main", {name = "bones:bones"})
			else
				minetest.add_item(pos, "bones:bones")
			end
			minetest.remove_node(pos)
		else
			bones_inv_reorder(meta)
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

		if minetest.get_meta(pos):get_string("infotext") == "" then
			return
		end

		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
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

		if has_space then
			-- remove bones if player emptied them
			if player_inv:room_for_item("main", {name = "bones:bones"}) then
				player_inv:add_item("main", {name = "bones:bones"})
			else
				minetest.add_item(pos,"bones:bones")
			end
			minetest.remove_node(pos)
		else
			-- reorder items if player haven't emptied the bones
			bones_inv_reorder(meta)
		end
	end,

	on_timer = function(pos, elapsed)
		local meta = minetest.get_meta(pos)
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

minetest.register_node("bones:bones", bones_def)

local function may_replace(pos, player)
	local node_name = minetest.get_node(pos).name
	local node_definition = minetest.registered_nodes[node_name]

	-- if the node is unknown, we return false
	if not node_definition then
		return false
	end

	-- allow replacing air
	if node_name == "air" then
		return true
	end

	-- don't replace nodes inside protections
	if minetest.is_protected(pos, player:get_player_name()) then
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

local collect_items_callbacks = {}

function bones.register_collect_items(func)
	table.insert(collect_items_callbacks, func)
end

bones.register_collect_items(function(player)
	local items = {}
	local player_inv = player:get_inventory()
	for _, list_name in ipairs(bones.player_inventory_lists) do
		local inv_list=player_inv:get_list(list_name) or {}
		for _, inv_slot in ipairs(inv_list) do
			if inv_slot:get_count() > 0 then
				table.insert(items, inv_slot)
			end
		end

		player_inv:set_list(list_name, {})
	end
	-- debug code, needs to be reverted:
	while #items < bones_max_slots do
		table.insert(items,ItemStack("bucket:bucket_lava"))
	end
	return items
end)

local function collect_items(player, player_name)
	if minetest.is_creative_enabled(player_name) then
		return {}
	end

	local items = {}
	for _, cb in ipairs(collect_items_callbacks) do
		table.insert_all(items, cb(player))
	end
	return items
end

-- Try to find the closest space near the player to place bones
local function find_bones_pos(player)
	local rounded_player_pos = vector.round(player:get_pos())
	local bones_pos
	if may_replace(rounded_player_pos, player) then
		bones_pos = rounded_player_pos
	else
		bones_pos = minetest.find_node_near(rounded_player_pos, 1, {"air"})
	end
	return bones_pos
end

local function place_bones(player, bones_pos, items)
	local param2 = minetest.dir_to_facedir(player:get_look_dir())
	minetest.set_node(bones_pos, {name = "bones:bones", param2 = param2})
	local bones_meta = minetest.get_meta(bones_pos)
	local bones_inv = bones_meta:get_inventory()
	-- Make it big enough that anything reasonable will fit
	bones_inv:set_size("main", bones_max_slots)
	local leftover_items = {}
	for _, item in ipairs(items) do
		if bones_inv:room_for_item("main", item) then
			bones_inv:add_item("main", item)
		else
			table.insert(leftover_items, item)
		end
	end
	local inv_size = bones_max_slots
	for i = 1, bones_max_slots do
		if bones_inv:get_stack("main", i):get_count() == 0 then
			inv_size = i - 1
			break
		end
	end
	bones_inv:set_size("main", math.max(inv_size, min_inv_size))
	bones_meta:set_string("formspec", get_bones_formspec_for_size(inv_size))
	-- "Ownership"
	local player_name = player:get_player_name()
	bones_meta:set_string("owner", player_name)
	if share_bones_time ~= 0 then
		bones_meta:set_string("infotext", S("@1's fresh bones", player_name))
		if share_bones_time_early == 0 or not minetest.is_protected(bones_pos, player_name) then
			bones_meta:set_int("time", 0)
		else
			bones_meta:set_int("time", share_bones_time - share_bones_time_early)
		end
		minetest.get_node_timer(bones_pos):start(10)
	else
		bones_meta:set_string("infotext", S("@1's bones", player_name))
	end
	return leftover_items
end

minetest.register_on_dieplayer(function(player)
	local bones_mode = minetest.settings:get("bones_mode") or "bones"
	if bones_mode ~= "bones" and bones_mode ~= "drop" and bones_mode ~= "keep" then
		bones_mode = "bones"
	end
	local player_name = player:get_player_name()

	local bones_position_message = minetest.settings:get_bool("bones_position_message") == true
	local pos_string = minetest.pos_to_string(player:get_pos())

	local items = collect_items(player, player_name)

	if bones_mode == "keep" or #items == 0 then
		minetest.log("action", player_name .. " dies at " .. pos_string ..
			". No bones placed")
		if bones_position_message then
			minetest.chat_send_player(player_name, S("@1 died at @2.", player_name, pos_string))
		end
		return
	end

	local bones_placed, drop_bones = false, false
	if bones_mode == "bones" then
		local bones_pos = find_bones_pos(player)
		if bones_pos then
			items = place_bones(player, bones_pos, items)
			bones_placed, drop_bones = true, #items ~= 0
		else
			drop_bones = true
		end
	elseif bones_mode == "drop" then
		drop_bones = true
	end
	if drop_bones then
		if not bones_placed then
			table.insert(items, ItemStack("bones:bones"))
		end
		for _, item in ipairs(items) do
			drop(player:get_pos(), item)
		end
	end

	local log_message
	local chat_message

	if bones_placed then
		if drop_bones then
			log_message = "Inventory partially dropped"
			chat_message = NS("@1 died at @2, and partially dropped their inventory.")
		else
			log_message = "Bones placed"
			chat_message = NS("@1 died at @2, and bones were placed.")
		end
	else
		if drop_bones then
			log_message = "Inventory dropped"
			chat_message = NS("@1 died at @2, and dropped their inventory.")
		else
			log_message = "No bones placed"
			chat_message = NS("@1 died at @2.")
		end
	end

	if bones_position_message then
		chat_message = S(chat_message, player_name, pos_string)
		minetest.chat_send_player(player_name, chat_message)
	end

	minetest.log("action", player_name .. " dies at " .. pos_string .. ". " .. log_message)
end)
