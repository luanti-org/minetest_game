-- Parameters

-- Node search radius around player
local radius = 8

local allsounds = {
	["env_sounds_water"] = {
		trigger = {"default:water_flowing", "default:river_water_flowing"},
		base_volume = 0.04,
		max_volume = 0.4,
		per_node = 0.004,
	},
	["env_sounds_lava"] = {
		trigger = {"default:lava_source", "default:lava_flowing"},
		base_volume = 0,
		max_volume = 0.6,
		per_node = {
			["default:lava_source"] = 0.008,
			["default:lava_flowing"] = 0.002,
		},
	},
}

if minetest.settings:get_bool("river_source_sounds") then
	table.insert(allsounds["env_sounds_water"].trigger,
		"default:river_water_source")
end


-- Cache the union of all trigger nodes

local cache_triggers = {}

for sound, def in pairs(allsounds) do
	for _, name in ipairs(def.trigger) do
		table.insert(cache_triggers, name)
	end
end


-- Update sound for player

local function update_sound(player)
	local player_name = player:get_player_name()
	local ppos = player:get_pos()
	ppos = vector.add(ppos, player:get_properties().eye_height)
	local areamin = vector.subtract(ppos, radius)
	local areamax = vector.add(ppos, radius)

	local pos = minetest.find_nodes_in_area(areamin, areamax, cache_triggers, true)
	if next(pos) == nil then -- If table empty
		return
	end
	for sound, def in pairs(allsounds) do
		-- Find average position
		local posav = {0, 0, 0}
		local count = 0
		for _, name in ipairs(def.trigger) do
			if pos[name] then
				for _, p in ipairs(pos[name]) do
					posav[1] = posav[1] + p.x
					posav[2] = posav[2] + p.y
					posav[3] = posav[3] + p.z
				end
				count = count + #pos[name]
			end
		end

		if count > 0 then
			posav = vector.new(posav[1] / count, posav[2] / count,
				posav[3] / count)

			-- Calculate gain
			local gain = def.base_volume
			if type(def.per_node) == 'table' then
				for name, multiplier in pairs(def.per_node) do
					if pos[name] then
						gain = gain + #pos[name] * multiplier
					end
				end
			else
				gain = gain + count * def.per_node
			end
			gain = math.min(gain, def.max_volume)

			minetest.sound_play(sound, {
				pos = posav,
				to_player = player_name,
				gain = gain,
			}, true)
		end
	end
end


-- Update sound when player joins

minetest.register_on_joinplayer(function(player)
	update_sound(player)
end)


-- Cyclic sound update

local function cyclic_update()
	for _, player in pairs(minetest.get_connected_players()) do
		update_sound(player)
	end
	minetest.after(3.5, cyclic_update)
end

minetest.after(0, cyclic_update)
