unused_args = false
allow_defined_top = true

globals = {
	"default"
}

read_globals = {
	"DIR_DELIM",
	"core",
	"minetest",
	"dump",
	"vector",
	"VoxelManip", "VoxelArea",
	"PseudoRandom", "PcgRandom",
	"ItemStack",
	"Settings",
	"unpack",
	-- Silence errors about custom table methods.
	table = { fields = { "copy", "indexof" } },
	-- Silence warnings about accessing undefined fields of global 'math'
	math = { fields = { "sign" } },
	-- Mod support
	"player_monoids",
	"pova",
}

-- Overwrites minetest.handle_node_drops
files["mods/creative/init.lua"].globals = { "minetest" }

-- Overwrites minetest.calculate_knockback
files["mods/player_api/api.lua"].globals = { "minetest" }

-- Don't report on legacy definitions of globals.
files["mods/default/legacy.lua"].global = false
