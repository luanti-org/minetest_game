-- Disable by mapgen, setting or if 'static_spawnpoint' is set
--------------------------------------------------------------

local mg_name = minetest.get_mapgen_setting("mg_name")
if mg_name == "v6" or mg_name == "singlenode" or
		minetest.settings:get("static_spawnpoint") or
		minetest.settings:get_bool("engine_spawn") then
	return
end


-- Parameters
-------------

-- Resolution of search grid in nodes.
local res = 64
-- Number of points checked in the square search grid (edge * edge).
local checks = 128 * 128
-- Starting point for biome checks. This also sets the y co-ordinate for all
-- points checked, so the suitable biomes must be active at this y.
local pos = {x = 0, y = 8, z = 0}


-- Table of suitable biomes

local biome_ids = {
	minetest.get_biome_id("taiga"),
	minetest.get_biome_id("coniferous_forest"),
	minetest.get_biome_id("deciduous_forest"),
	minetest.get_biome_id("grassland"),
	minetest.get_biome_id("savanna"),
}

-- End of parameters
--------------------


-- Direction table

local dirs = {
	{x = 0, y = 0, z = 1},
	{x = -1, y = 0, z = 0},
	{x = 0, y = 0, z = -1},
	{x = 1, y = 0, z = 0},
}


-- Initial variables

local edge_len = 1
local edge_dist = 0
local dir_step = 0
local dir_ind = 1
local searched = false
local success = false
local spawn_pos = {}


--Functions
-----------

-- Get next position on square search spiral

local function next_pos()
	if edge_dist == edge_len then
		edge_dist = 0
		dir_ind = dir_ind + 1
		if dir_ind == 5 then
			dir_ind = 1
		end
		dir_step = dir_step + 1
		edge_len = math.floor(dir_step / 2) + 1
	end

	local dir = dirs[dir_ind]
	local move = vector.multiply(dir, res)

	edge_dist = edge_dist + 1

	return vector.add(pos, move)
end


-- Spawn position search

local function search()
	local t0 = os.clock()
	for iter = 1, checks do
		local biome_data = minetest.get_biome_data(pos)
		-- Sometimes biome_data is nil
		local biome = biome_data and biome_data.biome
		for id_ind = 1, #biome_ids do
			local biome_id = biome_ids[id_ind]
			if biome == biome_id then
				print("suitable biome found")
				local spawn_y = minetest.get_spawn_level(pos.x, pos.z)
				if spawn_y then
					print("suitable level found")
					print("at iteration " .. iter)
					spawn_pos = {x = pos.x, y = spawn_y, z = pos.z}
					print("spawn pos x " .. spawn_pos.x ..
						"  y " .. spawn_pos.y .. "  z " .. spawn_pos.z)
					local time = math.ceil((os.clock() - t0) * 1000)
					print ("search time " .. time .. " ms")
					return true
				end
			end
		end

		pos = next_pos()
	end

	print("search failed, use engine spawn pos")
	local time = math.ceil((os.clock() - t0) * 1000)
	print ("search time " .. time .. " ms")
	return false
end


-- On new player spawn

-- Search for new player spawn once per server session. If successful, store
-- position and reposition new players, otherwise leave them at engine spawn
-- position.

minetest.register_on_newplayer(function(player)
	if not searched then
		success = search()
		searched = true
	end

	if success then
		print("move player to search pos")
		player:setpos(spawn_pos)
	end
end)
