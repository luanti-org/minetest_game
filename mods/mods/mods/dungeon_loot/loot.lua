-- Loot from the `default` mod is registered here,
-- with the rest being registered in the respective mods

dungeon_loot.registered_loot = {
	-- various items
	{name = "default:stick", chance = 0.6, count = {3, 6}},
	{name = "default:flint", chance = 0.4, count = {1, 3}},

	-- farming / consumable
	{name = "default:apple", chance = 0.4, count = {1, 4}},
	{name = "default:cactus", chance = 0.4, count = {1, 4},
		types = {"sandstone", "desert"}},

	-- minerals
	{name = "default:coal_lump", chance = 0.9, count = {1, 12}},
	{name = "default:gold_ingot", chance = 0.5},
	{name = "default:steel_ingot", chance = 0.4, count = {1, 6}},
	{name = "default:mese_crystal", chance = 0.1, count = {2, 3}},

	-- tools
	{name = "default:sword_wood", chance = 0.6},
	{name = "default:pick_stone", chance = 0.3},
	{name = "default:axe_diamond", chance = 0.05},

	-- natural materials
	{name = "default:sand", chance = 0.8, count = {4, 32}, y = {-64, 32768},
		types = {"normal"}},
	{name = "default:desert_sand", chance = 0.8, count = {4, 32}, y = {-64, 32768},
		types = {"sandstone"}},
	{name = "default:desert_cobble", chance = 0.8, count = {4, 32},
		types = {"desert"}},
	{name = "default:snow", chance = 0.8, count = {8, 64}, y = {-64, 32768},
		types = {"ice"}},
	{name = "default:dirt", chance = 0.6, count = {2, 16}, y = {-64, 32768},
		types = {"normal", "sandstone", "desert"}},
	{name = "default:obsidian", chance = 0.25, count = {1, 3}, y = {-32768, -512}},
	{name = "default:mese", chance = 0.15, y = {-32768, -512}},
}

function dungeon_loot.register(t)
	if t.name ~= nil then
		t = {t} -- single entry
	end
	for _, loot in ipairs(t) do
		table.insert(dungeon_loot.registered_loot, loot)
	end
end

function dungeon_loot._internal_get_loot(pos_y, dungeontype)
	-- filter by y pos and type
	local ret = {}
	for _, l in ipairs(dungeon_loot.registered_loot) do
		if l.y == nil or (pos_y >= l.y[1] and pos_y <= l.y[2]) then
			if l.types == nil or table.indexof(l.types, dungeontype) ~= -1 then
				table.insert(ret, l)
			end
		end
	end
	return ret
end
