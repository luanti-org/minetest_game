-- mods/default/tools.lua

-- support for MT game translation.
local S = default.get_translator

-- The hand
-- Override the hand item registered in the engine in builtin/game/register.lua
minetest.override_item("", {
	wield_scale = {x=1,y=1,z=2.5},
	tool_capabilities = {
		full_punch_interval = 0.9,
		max_drop_level = 0,
		groupcaps = {
			crumbly = {times={[2]=3.00, [3]=0.70}, uses=0, maxlevel=1},
			snappy = {times={[3]=0.40}, uses=0, maxlevel=1},
			oddly_breakable_by_hand = {times={[1]=3.50,[2]=2.00,[3]=0.70}, uses=0}
		},
		damage_groups = {fleshy=1},
	}
})

--
-- Picks
--

local function register_pick(tool_def)
	if tool_def.groups == nil then
		tool_def.groups = {}
	end
	tool_def.groups["pickaxe"] = 1
	minetest.register_tool("default:pick_"..tool_def.name, {
		description = tool_def.desc,
		inventory_image = "default_tool_"..tool_def.name.."pick.png",
		tool_capabilities = {
			full_punch_interval = tool_def.full_punch_interval,
			max_drop_level = tool_def.max_drop_level,
			groupcaps = {cracky = tool_def.groupcap},
			damage_groups = {fleshy = tool_def.damage_fleshy},
		},
		sound = {breaks = "default_tool_breaks"},
		groups = tool_def.groups,
	})
	minetest.register_craft({
		output = "default:pick_"..tool_def.name,
		recipe = {
			{tool_def.material, tool_def.material, tool_def.material},
			{"", "group:stick", ""},
			{"", "group:stick", ""}
		}
	})
end

register_pick({
	name = "wood",
	desc = S("Wooden Pickaxe"),
	full_punch_interval = 1.2,
	max_drop_level = 0,
	groupcap = {times = {[3]=1.60}, uses=10, maxlevel=1},
	damage_fleshy = 2,
	groups = {flammable = 2},
	material = "group:wood"
})

register_pick({
	name = "stone",
	desc = S("Stone Pickaxe"),
	full_punch_interval = 1.3,
	max_drop_level = 0,
	groupcap = {times = {[2]=2.0, [3]=1.00}, uses=20, maxlevel = 1},
	damage_fleshy = 3,
	material = "group:stone"
})

register_pick({
	name = "bronze",
	desc = S("Bronze Pickaxe"),
	full_punch_interval = 1.0,
	max_drop_level = 1,
	groupcap = {times = {[1]=4.50, [2]=1.80, [3]=0.90}, uses=20, maxlevel = 2},
	damage_fleshy = 4,
	material = "default:bronze_ingot"
})

register_pick({
	name = "steel",
	desc = S("Steel Pickaxe"),
	full_punch_interval = 1.0,
	max_drop_level = 1,
	groupcap = {times = {[1]=4.00, [2]=1.60, [3]=0.80}, uses=20, maxlevel = 2},
	damage_fleshy = 4,
	material = "default:steel_ingot"
})

register_pick({
	name = "mese",
	desc = S("Mese Pickaxe"),
	full_punch_interval = 0.9,
	max_drop_level = 3,
	groupcap = {times = {[1]=2.4, [2]=1.2, [3]=0.60}, uses=20, maxlevel = 3},
	damage_fleshy = 5,
	material = "default:mese_crystal"
})

register_pick({
	name = "diamond",
	desc = S("Diamond Pickaxe"),
	full_punch_interval = 0.9,
	max_drop_level = 3,
	groupcap = {times = {[1]=2.0, [2]=1.0, [3]=0.50}, uses=30, maxlevel = 3},
	damage_fleshy = 5,
	material = "default:diamond"
})

--
-- Shovels
--

local function register_shovel(tool_def)
	if tool_def.groups == nil then
		tool_def.groups = {}
	end
	tool_def.groups["shovel"] = 1
	minetest.register_tool("default:shovel_"..tool_def.name, {
		description = tool_def.desc,
		inventory_image = "default_tool_"..tool_def.name.."shovel.png",
		wield_image = "default_tool_"..tool_def.name.."shovel.png^[transformR90",
		tool_capabilities = {
			full_punch_interval = tool_def.full_punch_interval,
			max_drop_level = tool_def.max_drop_level,
			groupcaps = {crumbly = tool_def.groupcap},
			damage_groups = {fleshy = tool_def.damage_fleshy},
		},
		sound = {breaks = "default_tool_breaks"},
		groups = tool_def.groups
	})
	minetest.register_craft({
		output = "default:shovel_"..tool_def.name,
		recipe = {
			{tool_def.material},
			{"group:stick"},
			{"group:stick"}
		}
	})
end

register_shovel({
	name = "wood",
	desc = S("Wooden Shovel"),
	full_punch_interval = 1.2,
	max_drop_level = 0,
	groupcap = {times = {[1]=3.00, [2]=1.60, [3]=0.60}, uses=10, maxlevel=1},
	damage_fleshy = 2,
	groups = {flammable = 2},
	material = "group:wood"
})

register_shovel({
	name = "stone",
	desc = S("Stone Shovel"),
	full_punch_interval = 1.4,
	max_drop_level = 0,
	groupcap = {times = {[1]=1.80, [2]=1.20, [3]=0.50}, uses=20, maxlevel=1},
	damage_fleshy = 2,
	material = "group:stone"
})

register_shovel({
	name = "bronze",
	desc = S("Bronze Shovel"),
	full_punch_interval = 1.1,
	max_drop_level = 1,
	groupcap = {times = {[1]=1.65, [2]=1.05, [3]=0.45}, uses=25, maxlevel=2},
	damage_fleshy = 3,
	material = "default:bronze_ingot"
})

register_shovel({
	name = "steel",
	desc = S("Steel Shovel"),
	full_punch_interval = 1.1,
	max_drop_level = 1,
	groupcap = {times = {[1]=1.50, [2]=0.90, [3]=0.40}, uses=30, maxlevel=2},
	damage_fleshy = 3,
	material = "default:steel_ingot"
})

register_shovel({
	name = "mese",
	desc = S("Mese Shovel"),
	full_punch_interval = 1.0,
	max_drop_level = 3,
	groupcap = {times = {[1]=1.20, [2]=0.60, [3]=0.30}, uses=20, maxlevel=3},
	damage_fleshy = 4,
	material = "default:mese_crystal"
})

register_shovel({
	name = "diamond",
	desc = S("Diamond Shovel"),
	full_punch_interval = 1.0,
	max_drop_level = 1,
	groupcap = {times = {[1]=1.10, [2]=0.50, [3]=0.30}, uses=30, maxlevel=3},
	damage_fleshy = 4,
	material = "default:diamond"
})

--
-- Axes
--

local function register_axe(tool_def)
	if tool_def.groups == nil then
		tool_def.groups = {}
	end
	tool_def.groups["axe"] = 1
	minetest.register_tool("default:axe_"..tool_def.name, {
		description = tool_def.desc,
		inventory_image = "default_tool_"..tool_def.name.."axe.png",
		tool_capabilities = {
			full_punch_interval = tool_def.full_punch_interval,
			max_drop_level = tool_def.max_drop_level,
			groupcaps = {choppy = tool_def.groupcap},
			damage_groups = {fleshy = tool_def.damage_fleshy},
		},
		sound = {breaks = "default_tool_breaks"},
		groups = tool_def.groups
	})
	minetest.register_craft({
		output = "default:axe_"..tool_def.name,
		recipe = {
			{tool_def.material, tool_def.material},
			{tool_def.material, "group:stick"},
			{"", "group:stick"}
		}
	})
end

register_axe({
	name = "wood",
	desc = S("Wooden Axe"),
	full_punch_interval = 1.0,
	max_drop_level = 0,
	groupcap = {times = {[2]=3.00, [3]=1.60}, uses=10, maxlevel=1},
	damage_fleshy = 2,
	groups = {flammable = 2},
	material = "group:wood"
})

register_axe({
	name = "stone",
	desc = S("Stone Axe"),
	full_punch_interval = 1.2,
	max_drop_level = 0,
	groupcap = {times = {[1]=3.00, [2]=2.00, [3]=1.30}, uses=20, maxlevel=1},
	damage_fleshy = 3,
	material = "group:stone"
})

register_axe({
	name = "bronze",
	desc = S("Bronze Axe"),
	full_punch_interval = 1.0,
	max_drop_level = 1,
	groupcap = {times = {[1]=2.75, [2]=1.70, [3]=1.15}, uses=20, maxlevel=2},
	damage_fleshy = 4,
	material = "default:bronze_ingot"
})

register_axe({
	name = "steel",
	desc = S("Steel Axe"),
	full_punch_interval = 1.0,
	max_drop_level = 1,
	groupcap = {times = {[1]=2.50, [2]=1.40, [3]=1.00}, uses=20, maxlevel=2},
	damage_fleshy = 4,
	material = "default:steel_ingot"
})

register_axe({
	name = "mese",
	desc = S("Mese Axe"),
	full_punch_interval = 0.9,
	max_drop_level = 1,
	groupcap = {times = {[1]=2.20, [2]=1.00, [3]=0.60}, uses=20, maxlevel=3},
	damage_fleshy = 6,
	material = "default:mese_crystal"
})

register_axe({
	name = "diamond",
	desc = S("Diamond Axe"),
	full_punch_interval = 0.9,
	max_drop_level = 1,
	groupcap = {times = {[1]=2.10, [2]=0.90, [3]=0.50}, uses=30, maxlevel=3},
	damage_fleshy = 7,
	material = "default:diamond"
})

--
-- Swords
--

local function register_sword(tool_def)
	if tool_def.groups == nil then
		tool_def.groups = {}
	end
	tool_def.groups["sword"] = 1
	minetest.register_tool("default:sword_"..tool_def.name, {
		description = tool_def.desc,
		inventory_image = "default_tool_"..tool_def.name.."sword.png",
		tool_capabilities = {
			full_punch_interval = tool_def.full_punch_interval,
			max_drop_level = tool_def.max_drop_level,
			groupcaps = {snappy = tool_def.groupcap},
			damage_groups = {fleshy = tool_def.damage_fleshy},
		},
		sound = {breaks = "default_tool_breaks"},
		groups = tool_def.groups
	})
	minetest.register_craft({
		output = "default:sword_"..tool_def.name,
		recipe = {
			{tool_def.material},
			{tool_def.material},
			{"group:stick"}
		}
	})
end

register_sword({
	name = "wood",
	desc = S("Wooden Sword"),
	full_punch_interval = 1,
	max_drop_level = 0,
	groupcap = {times = {[2]=1.6, [3]=0.40}, uses=10, maxlevel=1},
	damage_fleshy = 2,
	groups = {flammable = 2},
	material = "group:wood"
})

register_sword({
	name = "stone",
	desc = S("Stone Sword"),
	full_punch_interval = 1.2,
	max_drop_level = 0,
	groupcap = {times = {[2]=1.4, [3]=0.40}, uses=20, maxlevel=1},
	damage_fleshy = 4,
	material = "group:stone"
})

register_sword({
	name = "bronze",
	desc = S("Bronze Sword"),
	full_punch_interval = 0.8,
	max_drop_level = 1,
	groupcap = {times = {[1]=2.75, [2]=1.30, [3]=0.375}, uses=25, maxlevel=2},
	damage_fleshy = 6,
	material = "default:bronze_ingot"
})

register_sword({
	name = "steel",
	desc = S("Steel Sword"),
	full_punch_interval = 0.8,
	max_drop_level = 1,
	groupcap = {times = {[1]=2.5, [2]=1.20, [3]=0.35}, uses=30, maxlevel=2},
	damage_fleshy = 6,
	material = "default:steel_ingot"
})

register_sword({
	name = "mese",
	desc = S("Mese Sword"),
	full_punch_interval = 0.7,
	max_drop_level = 1,
	groupcap = {times = {[1]=2.0, [2]=1.00, [3]=0.35}, uses=30, maxlevel=3},
	damage_fleshy = 7,
	material = "default:mese_crystal"
})

register_sword({
	name = "diamond",
	desc = S("Diamond Sword"),
	full_punch_interval = 0.7,
	max_drop_level = 1,
	groupcap = {times = {[1]=1.90, [2]=0.90, [3]=0.30}, uses=40, maxlevel=3},
	damage_fleshy = 8,
	material = "default:diamond"
})

-- Fuel recipes for wooden tools

minetest.register_craft({
	type = "fuel",
	recipe = "default:pick_wood",
	burntime = 6,
})

minetest.register_craft({
	type = "fuel",
	recipe = "default:shovel_wood",
	burntime = 4,
})

minetest.register_craft({
	type = "fuel",
	recipe = "default:axe_wood",
	burntime = 6,
})

minetest.register_craft({
	type = "fuel",
	recipe = "default:sword_wood",
	burntime = 5,
})
