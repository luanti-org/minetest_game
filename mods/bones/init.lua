-- bones/init.lua

-- Minetest Game mod: bones
-- See README.txt for licensing and other information.

-- Load support for MT game translation.
local S = minetest.get_translator("bones")
-- bones are supposed to hold up to 4*8+6+4*3*8+4+3*3 item slots:
-- 4*8 for the main inventory
-- 6 for the 3d_armor
-- (at most) 4*3*8 for 4 backpack worth of items (unified inventory)
-- 4 more for the actual backpacks
-- 3*3 more for the crafting grid
-- that adds up to 147, so 150 slots would be sufficient
local cols=15
local rows=10

bones = {
	private={
		dead_player_callbacks={}
	},
	public={}
}

local function is_owner(pos, name)
	local owner = minetest.get_meta(pos):get_string("owner")
	if owner == "" or owner == name or minetest.check_player_privs(name, "protection_bypass") then
		return true
	end
	return false
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

local bones_formspec =
	"size["..cols..","..(rows+5).."]" ..
	"list[current_name;main;0,0.3;"..cols..","..rows..";]" ..
	"list[current_player;main;"..((cols-8)/2)..","..rows..".85;8,1;]" ..
	"list[current_player;main;"..((cols-8)/2)..","..(rows+2)..".08;8,3;8]" ..
	"listring[current_name;main]" ..
	"listring[current_player;main]" ..
	default.get_hotbar_bg(0,4.85)

local share_bones_time = tonumber(minetest.settings:get("share_bones_time")) or 1200
local share_bones_time_early = tonumber(minetest.settings:get("share_bones_time_early")) or share_bones_time / 4

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

		local inv = minetest.get_meta(pos):get_inventory()
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
				minetest.add_item(pos,"bones:bones")
			end
			minetest.remove_node(pos)
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

local function is_all_empty(player_inv)
	for _, list_name in ipairs(player_inventory_lists) do
		if not player_inv:is_empty(list_name) then
			return false
		end
	end
	return true
end

--functions registered this way won't becalled if bones_mode is keep
function bones.public.register_transfer_inventory_to_bones_on_player_death(func)
	bones.private.dead_player_callbacks[#(bones.private.dead_player_callbacks)]=func
end

--drop or put into bones based on config and free slots in the bones
--supposed to be called from functions registered to bones.public.register_transfer_inventory_to_bones_on_player_death
function bones.public.transfer_stack_to_bones(stk)
	-- check if it's possible to place bones, if not find space near player
	if ( ( bones.private.current_dead_player.bones_mode == "bones" ) and ( bones.private.current_dead_player.bones_pos == nil ) ) then
		bones.private.current_dead_player.bones_pos = bones.private.current_dead_player.player_pos
		local air
		if ( may_replace(bones.private.current_dead_player.bones_pos, bones.private.current_dead_player.player) ) then
			air = bones.private.current_dead_player.bones_pos
		else
			air = minetest.find_node_near(bones.private.current_dead_player.bones_pos, 1, {"air"})
		end

		if air and not minetest.is_protected(air, bones.private.current_dead_player.player_name) then
			bones.private.current_dead_player.bones_pos = air
			local param2 = minetest.dir_to_facedir(bones.private.current_dead_player.player:get_look_dir())
			minetest.set_node(bones.private.current_dead_player.bones_pos, {name = "bones:bones", param2 = param2})
			local meta = minetest.get_meta(bones.private.current_dead_player.bones_pos)
			bones.private.current_dead_player.bones_inv = meta:get_inventory()
			bones.private.current_dead_player.bones_inv:set_size("main", cols * rows)
		else
			bones.private.current_dead_player.bones_mode = "drop"
			bones.private.current_dead_player.bones_pos = nil
		end
	end

	if ( ( bones.private.current_dead_player.bones_mode == "bones" ) and ( bones.private.current_dead_player.bones_inv:room_for_item("main", stk) ) ) then
		bones.private.current_dead_player.bones_inv:add_item("main", stk)
	else
		drop(bones.private.current_dead_player.player_pos, stk)
		bones.private.current_dead_player.dropped=true
	end
end

local function player_dies_transfer_inventory(player)
	local player_inv = player:get_inventory()
	for _, list_name in ipairs(player_inventory_lists) do
		for i = 1, player_inv:get_size(list_name) do
			local stack = player_inv:get_stack(list_name, i)
			bones.public.transfer_stack_to_bones(stack)
		end
		player_inv:set_list(list_name, {})
	end
end

bones.public.register_transfer_inventory_to_bones_on_player_death(player_dies_transfer_inventory)

minetest.register_on_dieplayer(function(player)
	local pos = vector.round(player:get_pos())
	local bones_mode = minetest.settings:get("bones_mode") or "bones"
	if bones_mode ~= "bones" and bones_mode ~= "drop" and bones_mode ~= "keep" then
		bones_mode = "bones"
	end
	local player_name = player:get_player_name()
	bones.private.current_dead_player={player=player, player_name=player_name, bones_inv=nil, bones_pos=nil, bones_mode=bones_mode, player_pos=pos, dropped=false}

	local bones_position_message = minetest.settings:get_bool("bones_position_message") == true
	local pos_string = minetest.pos_to_string(pos)

	-- return if keep inventory set or in creative mode
	if bones_mode == "keep" or minetest.is_creative_enabled(player_name) then
		minetest.log("action", player_name .. " dies at " .. pos_string ..
			". No bones placed")
		if bones_position_message then
			minetest.chat_send_player(player_name, S("@1 died at @2.", player_name, pos_string))
		end
		return
	end

	for i=0,#bones.private.dead_player_callbacks do
		local fun=bones.private.dead_player_callbacks[i]
		fun(player)
	end

	local bones_conclusion=""
	local public_conclusion=""

	if(not(bones.private.current_dead_player.bones_pos))then
		drop(bones.private.current_dead_player.player_pos, ItemStack("bones:bones"))
		if(not(bones.private.current_dead_player.dropped))then
			bones_conclusion="No bones placed"
		else
			bones_conclusion="Inventory dropped"
			public_conclusion="dropped their inventory"
		end
	else
		if(not(bones.private.current_dead_player.dropped))then
			bones_conclusion="Bones placed"
			public_conclusion="bones were placed"
		else
			bones_conclusion="Inventory partially dropped"
			public_conclusion="partially dropped their inventory"
		end
	end

	minetest.log("action", player_name .. " dies at " .. pos_string ..
		". " .. bones_conclusion)

	if bones_position_message then
		if(public_conclusion~="")then
			public_conclusion=", and "..public_conclusion
		end
		minetest.chat_send_player(player_name, S("@1 died at @2@3.", player_name, pos_string, public_conclusion))
	end

	local meta = minetest.get_meta(bones.private.current_dead_player.bones_pos)
	meta:set_string("formspec", bones_formspec)
	meta:set_string("owner", player_name)

	if share_bones_time ~= 0 then
		meta:set_string("infotext", S("@1's fresh bones", player_name))

		if share_bones_time_early == 0 or not minetest.is_protected(pos, player_name) then
			meta:set_int("time", 0)
		else
			meta:set_int("time", (share_bones_time - share_bones_time_early))
		end

		minetest.get_node_timer(pos):start(10)
	else
		meta:set_string("infotext", S("@1's bones", player_name))
	end
	bones.private.current_dead_player=nil
end)
