spawn = {}

-- provide empty default implementations

function spawn.get_default_pos()
	return nil
end

function spawn.add_suitable_biome(biome)
end

-- Callback registration

spawn.registered_on_spawn = {}

function spawn.register_on_spawn(func)
	table.insert(spawn.registered_on_spawn, func)
end

-- Logic run on spawn

local use_engine_spawn = minetest.settings:get("static_spawnpoint") or
		minetest.settings:get_bool("engine_spawn")

local function on_spawn(player, is_new)
	-- Ask all callbacks first
	for _, cb in ipairs(spawn.registered_on_spawn) do
		if cb(player, is_new) then
			return true
		end
	end
	-- Fall back to default spawn
	if not use_engine_spawn then
		local pos = spawn.get_default_pos()
		if pos then
			player:set_pos(pos)
			return true
		end
	end
	return false
end

minetest.register_on_newplayer(function(player)
	on_spawn(player, true)
end)

minetest.register_on_respawnplayer(function(player)
	return on_spawn(player, false)
end)
