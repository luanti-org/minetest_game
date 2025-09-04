minetest.set_gen_notify({dungeon = true, temple = true})

local function noise3d_integer(noise, pos)
	return math.abs(math.floor(noise:get_3d(pos) * 0x7fffffff))
end

local function random_sample(rand, list, count)
	local ret = {}
	for n = 1, count do
		local idx = rand:next(1, #list)
		table.insert(ret, list[idx])
		table.remove(list, idx)
	end
	return ret
end

local function find_walls(cpos, is_temple)
	local is_wall = function(node)
		return node.name ~= "air" and node.name ~= "ignore"
	end

	local dirs = {{x=1, z=0}, {x=-1, z=0}, {x=0, z=1}, {x=0, z=-1}}
	local get_node = minetest.get_node

	local ret = {}
	local mindist = {x=0, z=0}
	local min = function(a, b) return a ~= 0 and math.min(a, b) or b end
	for _, dir in ipairs(dirs) do
		for i = 1, 9 do -- 9 = max room size / 2
			local pos = vector.add(cpos, {x=dir.x*i, y=0, z=dir.z*i})

			-- continue in that direction until we find a wall-like node
			local node = get_node(pos)
			if is_wall(node) then
				local front_below = vector.subtract(pos, {x=dir.x, y=1, z=dir.z})
				local above = vector.add(pos, {x=0, y=1, z=0})

				-- check that it:
				--- is at least 2 nodes high (not a staircase)
				--- has a floor
				if is_wall(get_node(front_below)) and is_wall(get_node(above)) then
					table.insert(ret, {pos = pos, facing = {x=-dir.x, y=0, z=-dir.z}})
					if dir.z == 0 then
						mindist.x = min(mindist.x, i-1)
					else
						mindist.z = min(mindist.z, i-1)
					end
				end
				-- abort even if it wasn't a wall cause something is in the way
				break
			end
		end
	end

	local biome = minetest.get_biome_data(cpos)
	biome = biome and minetest.get_biome_name(biome.biome) or ""
	local type = "normal"
	if is_temple or biome:find("desert") == 1 then
		type = "desert"
	elseif biome:find("sandstone_desert") == 1 then
		type = "sandstone"
	elseif biome:find("icesheet") == 1 then
		type = "ice"
	end

	return {
		walls = ret,
		size = {x=mindist.x*2, z=mindist.z*2},
		type = type,
	}
end

local function populate_chest(pos, rand, dungeontype)
	--minetest.chat_send_all("chest placed at " .. minetest.pos_to_string(pos) .. " [" .. dungeontype .. "]")
	--minetest.add_node(vector.add(pos, {x=0, y=1, z=0}), {name="default:torch", param2=1})

	local item_list = dungeon_loot._internal_get_loot(pos.y, dungeontype)
	-- take random (partial) sample of all possible items
	local sample_n = math.min(#item_list, dungeon_loot.STACKS_PER_CHEST_MAX)
	item_list = random_sample(rand, item_list, sample_n)

	-- apply chances / randomized amounts and collect resulting items
	local items = {}
	for _, loot in ipairs(item_list) do
		if rand:next(0, 1000) / 1000 <= loot.chance then
			local itemdef = minetest.registered_items[loot.name]
			local amount = 1
			if loot.count ~= nil then
				amount = rand:next(loot.count[1], loot.count[2])
			end

			if not itemdef then
				minetest.log("warning", "Registered loot item " .. loot.name .. " does not exist")
			elseif itemdef.tool_capabilities then
				for n = 1, amount do
					local wear = rand:next(0.20 * 65535, 0.75 * 65535) -- 20% to 75% wear
					table.insert(items, ItemStack({name = loot.name, wear = wear}))
				end
			elseif itemdef.stack_max == 1 then
				-- not stackable, add separately
				for n = 1, amount do
					table.insert(items, loot.name)
				end
			else
				table.insert(items, ItemStack({name = loot.name, count = amount}))
			end
		end
	end

	-- place items at random places in chest
	local inv = minetest.get_meta(pos):get_inventory()
	local listsz = inv:get_size("main")
	assert(listsz >= #items)
	for _, item in ipairs(items) do
		local index = rand:next(1, listsz)
		if inv:get_stack("main", index):is_empty() then
			inv:set_stack("main", index, item)
		else
			inv:add_item("main", item) -- space occupied, just put it anywhere
		end
	end
end


minetest.register_on_generated(function(minp, maxp, blockseed)
	local gennotify = minetest.get_mapgen_object("gennotify")
	local poslist = gennotify["dungeon"] or {}
	local n_dungeons = #poslist
	-- Add MGv6 desert temples to the list too
	for _, entry in ipairs(gennotify["temple"] or {}) do
		table.insert(poslist, entry)
	end
	if #poslist == 0 then return end

	local noise = minetest.get_perlin(10115, 4, 0.5, 1)
	local rand = PcgRandom(noise3d_integer(noise, poslist[1]))

	local candidates = {}
	-- process at most 8 rooms to keep runtime of this predictable
	local num_process = math.min(#poslist, 8)
	for i = 1, num_process do
		local room = find_walls(poslist[i], i > n_dungeons)
		-- skip small rooms and everything that doesn't at least have 3 walls
		if math.min(room.size.x, room.size.z) >= 4 and #room.walls >= 3 then
			table.insert(candidates, room)
		end
	end

	local num_chests = rand:next(dungeon_loot.CHESTS_MIN, dungeon_loot.CHESTS_MAX)
	num_chests = math.min(#candidates, num_chests)
	local rooms = random_sample(rand, candidates, num_chests)

	for _, room in ipairs(rooms) do
		-- choose place somewhere in front of any of the walls
		local wall = room.walls[rand:next(1, #room.walls)]
		local v, vi -- vector / axis that runs alongside the wall
		if wall.facing.x ~= 0 then
			v, vi = {x=0, y=0, z=1}, "z"
		else
			v, vi = {x=1, y=0, z=0}, "x"
		end
		local chestpos = vector.add(wall.pos, wall.facing)
		local off = rand:next(-room.size[vi]/2 + 1, room.size[vi]/2 - 1)
		chestpos = vector.add(chestpos, vector.multiply(v, off))

		if minetest.get_node(chestpos).name == "air" then
			-- make it face inwards to the room
			local facedir = minetest.dir_to_facedir(vector.multiply(wall.facing, -1))
			minetest.add_node(chestpos, {name = "default:chest", param2 = facedir})
			populate_chest(chestpos, PcgRandom(noise3d_integer(noise, chestpos)), room.type)
		end
	end
end)
