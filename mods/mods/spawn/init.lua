-- Always load the API
----------------------
dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/api.lua")

-- Disable biome-search implementation on unsuitable mapgens
------------------------------------------------------------

local mg_name = minetest.get_mapgen_setting("mg_name")
if mg_name == "v6" or mg_name == "singlenode" then
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


-- Table of suitable biomes and matching API function

local biome_ids = {}

function spawn.add_suitable_biome(biome)
	local id = minetest.get_biome_id(biome)
	assert(id ~= nil)
	biome_ids[id] = true
end

for _, name in ipairs({
	"taiga", "coniferous_forest", "deciduous_forest", "grassland", "savanna"
}) do
	local id = minetest.get_biome_id(name)
	if id then
		biome_ids[id] = true
	end
end

-- End of parameters
--------------------

-- Direction table

local dirs = {
	vector.new(0, 0, 1),
	vector.new(-1, 0, 0),
	vector.new(0, 0, -1),
	vector.new(1, 0, 0),
}


-- Initial variables

local edge_len = 1
local edge_dist = 0
local dir_step = 0
local dir_ind = 1
local searched = false
local success = false
local spawn_pos = {}


-- Functions
------------

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
	local edge1, edge2 = core.get_mapgen_edges()
	for iter = 1, checks do
		local biome_data = minetest.get_biome_data(pos)
		-- Sometimes biome_data is nil
		if biome_data and biome_ids[biome_data.biome] then
			local spawn_y = minetest.get_spawn_level(pos.x, pos.z)
			if spawn_y then
				spawn_pos = vector.new(pos.x, spawn_y, pos.z)
				return true
			end
		end

		pos = next_pos()
		-- Check for position being outside world edge
		if pos.x < edge1.x or pos.z < edge1.z or pos.x > edge2.x or pos.z > edge2.z then
			return false
		end
	end

	return false
end


function spawn.get_default_pos()
	-- Search for spawn position once per server session
	if not searched then
		success = search()
		searched = true
	end
	return success and spawn_pos
end
