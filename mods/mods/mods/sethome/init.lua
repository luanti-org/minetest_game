-- sethome/init.lua

sethome = {}

-- Load support for MT game translation.
local S = minetest.get_translator("sethome")


local homes_file = minetest.get_worldpath() .. "/homes"
local homepos = {}

local function loadhomes()
	local input = io.open(homes_file, "r")
	if not input then
		return -- no longer an error
	end

	-- Iterate over all stored positions in the format "x y z player" for each line
	for pos, name in input:read("*a"):gmatch("(%S+ %S+ %S+)%s([%w_-]+)[\r\n]") do
		homepos[name] = minetest.string_to_pos(pos)
	end
	input:close()
end

loadhomes()

sethome.set = function(name, pos)
	local player = minetest.get_player_by_name(name)
	if not player or not pos then
		return false
	end
	local player_meta = player:get_meta()
	player_meta:set_string("sethome:home", minetest.pos_to_string(pos))

	-- remove `name` from the old storage file
	if not homepos[name] then
		return true
	end
	local data = {}
	local output = io.open(homes_file, "w")
	if output then
		homepos[name] = nil
		for i, v in pairs(homepos) do
			table.insert(data, string.format("%.1f %.1f %.1f %s\n", v.x, v.y, v.z, i))
		end
		output:write(table.concat(data))
		io.close(output)
		return true
	end
	return true -- if the file doesn't exist - don't return an error.
end

sethome.get = function(name)
	local player = minetest.get_player_by_name(name)
	if not player then
		return false, S("This command can only be executed in-game!")
	end
	local player_meta = player:get_meta()
	local pos = minetest.string_to_pos(player_meta:get_string("sethome:home"))
	if pos then
		return pos
	end

	-- fetch old entry from storage table
	pos = homepos[name]
	if pos then
		return vector.new(pos)
	else
		return nil
	end
end

sethome.go = function(name)
	local pos = sethome.get(name)
	local player = minetest.get_player_by_name(name)
	if player and pos then
		player:set_pos(pos)
		return true
	end
	return false
end

minetest.register_privilege("home", {
	description = S("Can use /sethome and /home"),
	give_to_singleplayer = false
})

minetest.register_chatcommand("home", {
	description = S("Teleport you to your home point"),
	privs = {home = true},
	func = function(name)
		local player = minetest.get_player_by_name(name)
		if not player then
			return false, S("This command can only be executed in-game!")
		end
		if sethome.go(name) then
			return true, S("Teleported to home!")
		end
		return false, S("Set a home using /sethome")
	end,
})

minetest.register_chatcommand("sethome", {
	description = S("Set your home point"),
	privs = {home = true},
	func = function(name)
		name = name or "" -- fallback to blank name if nil
		local player = minetest.get_player_by_name(name)
		if player and sethome.set(name, player:get_pos()) then
			return true, S("Home set!")
		end
		return false, S("Player not found!")
	end,
})
