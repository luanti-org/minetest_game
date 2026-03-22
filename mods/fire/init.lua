-- fire/init.lua

-- Global namespace for functions
fire = {}

local S = core.get_translator("fire")

-- Default to enabled in singleplayer
local fire_enabled = core.settings:get("enable_fire") or "auto"
if fire_enabled == "auto" then
	fire_enabled = core.is_singleplayer()
	if core.settings:get_bool("disable_fire") then -- this is undocumented...?
		fire_enabled = false
	end
else
	fire_enabled = core.is_yes(fire_enabled)
end

--
-- Items
--

-- Flood flame function
local function flood_flame(pos, _, newnode)
	-- Play flame extinguish sound if liquid is not an 'igniter'
	if core.get_item_group(newnode.name, "igniter") == 0 then
		core.sound_play("fire_extinguish_flame",
			{ pos = pos, max_hear_distance = 16, gain = 0.15 }, true)
	end
	-- Remove the flame
	return false
end

-- Flame nodes
local fire_node = {
	drawtype = "firelike",
	tiles = { {
		name = "fire_basic_flame_animated.png",
		animation = {
			type = "vertical_frames",
			aspect_w = 16,
			aspect_h = 16,
			length = 1
		}
	}
	},
	inventory_image = "fire_basic_flame.png",
	paramtype = "light",
	light_source = 13,
	walkable = false,
	buildable_to = true,
	sunlight_propagates = true,
	floodable = true,
	damage_per_second = 4,
	groups = { igniter = 2, dig_immediate = 3, fire = 1 },
	drop = "",
	on_flood = flood_flame
}

-- Basic flame node
local flame_fire_node = table.copy(fire_node)
flame_fire_node.description = S("Fire")
flame_fire_node.groups.not_in_creative_inventory = 1
flame_fire_node.on_timer = function(pos)
	if not core.find_node_near(pos, 1, { "group:flammable" }) then
		core.remove_node(pos)
		return
	end
	-- Restart timer
	return true
end
flame_fire_node.on_construct = function(pos)
	core.get_node_timer(pos):start(math.random(30, 60))
end

core.register_node("fire:basic_flame", flame_fire_node)

-- Permanent flame node
local permanent_fire_node = table.copy(fire_node)
permanent_fire_node.description = S("Permanent Fire")

core.register_node("fire:permanent_flame", permanent_fire_node)

-- Flint and Steel
core.register_tool("fire:flint_and_steel", {
	description = S("Flint and Steel"),
	inventory_image = "fire_flint_steel.png",
	sound = { breaks = "default_tool_breaks" },

	on_use = function(itemstack, user, pointed_thing)
		local sound_pos = pointed_thing.above or user:get_pos()
		core.sound_play("fire_flint_and_steel",
			{ pos = sound_pos, gain = 0.2, max_hear_distance = 8 }, true)
		local player_name = user:get_player_name()
		if pointed_thing.type == "node" then
			local node_under = core.get_node(pointed_thing.under).name
			local nodedef = core.registered_nodes[node_under]
			if not nodedef then
				return
			end
			if core.is_protected(pointed_thing.under, player_name) then
				core.record_protection_violation(pointed_thing.under, player_name)
				return
			end
			if nodedef.on_ignite then
				nodedef.on_ignite(pointed_thing.under, user)
			elseif core.get_item_group(node_under, "flammable") >= 1
				and core.get_node(pointed_thing.above).name == "air" then
				if core.is_protected(pointed_thing.above, player_name) then
					core.record_protection_violation(pointed_thing.above, player_name)
					return
				end

				core.set_node(pointed_thing.above, { name = "fire:basic_flame" })
			end
		end
		if not core.is_creative_enabled(player_name) then
			-- Wear tool
			local wdef = itemstack:get_definition()
			itemstack:add_wear_by_uses(66)

			-- Tool break sound
			if itemstack:get_count() == 0 and wdef.sound and wdef.sound.breaks then
				core.sound_play(wdef.sound.breaks,
					{ pos = sound_pos, gain = 0.5 }, true)
			end
			return itemstack
		end
	end
})

core.register_craft({
	output = "fire:flint_and_steel",
	recipe = {
		{ "default:flint", "default:steel_ingot" }
	}
})

-- Override coalblock to enable permanent flame above
-- Coalblock is non-flammable to avoid unwanted basic_flame nodes
core.override_item("default:coalblock", {
	after_destruct = function(pos)
		pos.y = pos.y + 1
		if core.get_node(pos).name == "fire:permanent_flame" then
			core.remove_node(pos)
		end
	end,
	on_ignite = function(pos)
		local flame_pos = { x = pos.x, y = pos.y + 1, z = pos.z }
		if core.get_node(flame_pos).name == "air" then
			core.set_node(flame_pos, { name = "fire:permanent_flame" })
		end
	end
})


--
-- Sound
--

-- Enable if no setting present
local flame_sound = core.settings:get_bool("flame_sound", true)

if flame_sound then
	local handles = {}
	local timer = 0

	-- Parameters
	local radius = 8 -- Flame node search radius around player
	local cycle = 3 -- Cycle time for sound updates

	-- Update sound for player
	function fire.update_player_sound(player)
		local player_name = player:get_player_name()
		-- Search for flame nodes in radius around player
		local ppos = player:get_pos()
		local areamin = vector.subtract(ppos, radius)
		local areamax = vector.add(ppos, radius)
		local fpos, num = core.find_nodes_in_area(
			areamin,
			areamax,
			{ "fire:basic_flame", "fire:permanent_flame" }
		)
		-- Total number of flames in radius
		local flames = (num["fire:basic_flame"] or 0) +
			(num["fire:permanent_flame"] or 0)
		-- Stop previous sound
		if handles[player_name] then
			core.sound_stop(handles[player_name])
			handles[player_name] = nil
		end
		-- If flames
		if flames > 0 then
			-- Find centre of flame positions
			local fposmid = fpos[1]
			-- If more than 1 flame
			if #fpos > 1 then
				local fposmin = areamax
				local fposmax = areamin
				for i = 1, #fpos do
					local fposi = fpos[i]
					if fposi.x > fposmax.x then
						fposmax.x = fposi.x
					end
					if fposi.y > fposmax.y then
						fposmax.y = fposi.y
					end
					if fposi.z > fposmax.z then
						fposmax.z = fposi.z
					end
					if fposi.x < fposmin.x then
						fposmin.x = fposi.x
					end
					if fposi.y < fposmin.y then
						fposmin.y = fposi.y
					end
					if fposi.z < fposmin.z then
						fposmin.z = fposi.z
					end
				end
				fposmid = vector.divide(vector.add(fposmin, fposmax), 2)
			end
			-- Play sound, fading in to avoid abrupt restarts on each cycle
			local handle = core.sound_play(
				{ name = "fire_fire", fade = 0.5 },
				{
					pos = fposmid,
					to_player = player_name,
					gain = math.min(0.06 * (1 + flames * 0.125), 0.18),
					max_hear_distance = 32,
					loop = true,
					-- Start at a random offset so restarted sounds don't click
					start_time = math.random() * cycle,
				}
			)
			-- Store sound handle for this player
			if handle then
				handles[player_name] = handle
			end
		end
	end

	-- Cycle for updating player sounds
	core.register_globalstep(function(dtime)
		timer = timer + dtime
		if timer < cycle then
			return
		end

		timer = 0
		local players = core.get_connected_players()
		for n = 1, #players do
			fire.update_player_sound(players[n])
		end
	end)

	-- Stop sound and clear handle on player leave
	core.register_on_leaveplayer(function(player)
		local player_name = player:get_player_name()
		if handles[player_name] then
			core.sound_stop(handles[player_name])
			handles[player_name] = nil
		end
	end)
end


-- Deprecated function kept temporarily to avoid crashes if mod fire nodes call it
function fire.update_sounds_around() end

--
-- ABMs
--

if fire_enabled then
	-- Ignite neighboring nodes, add basic flames
	core.register_abm({
		label = "Ignite flame",
		nodenames = { "group:flammable" },
		neighbors = { "group:igniter" },
		interval = 7,
		chance = 12,
		catch_up = false,
		action = function(pos)
			local p = core.find_node_near(pos, 1, { "air" })
			if p then
				core.set_node(p, { name = "fire:basic_flame" })
			end
		end
	})

	-- Remove flammable nodes around basic flame
	core.register_abm({
		label = "Remove flammable nodes",
		nodenames = { "fire:basic_flame" },
		neighbors = "group:flammable",
		interval = 5,
		chance = 18,
		catch_up = false,
		action = function(pos)
			local p = core.find_node_near(pos, 1, { "group:flammable" })
			if not p then
				return
			end
			local flammable_node = core.get_node(p)
			local def = core.registered_nodes[flammable_node.name]
			if def.on_burn then
				def.on_burn(p)
			else
				core.remove_node(p)
				core.check_for_falling(p)
			end
		end
	})
end
