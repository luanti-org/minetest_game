-- butterflies/init.lua

-- Load support for MT game translation.
local S = minetest.get_translator("butterflies")

-- Legacy compatibility, when pointabilities don't exist, pointable is set to true.
local pointable_compat = not minetest.features.item_specific_pointabilities

-- register butterflies
local butter_list = {
	{"white",  S("White Butterfly")},
	{"red",    S("Red Butterfly")},
	{"violet", S("Violet Butterfly")}
}

for i in ipairs (butter_list) do
	local name = butter_list[i][1]
	local desc = butter_list[i][2]

	minetest.register_node("butterflies:butterfly_"..name, {
		description = desc,
		drawtype = "plantlike",
		tiles = {{
			name = "butterflies_butterfly_"..name.."_animated.png",
			animation = {
				type = "vertical_frames",
				aspect_w = 16,
				aspect_h = 16,
				length = 3
			},
		}},
		inventory_image = "butterflies_butterfly_"..name..".png",
		wield_image =  "butterflies_butterfly_"..name..".png",
		waving = 1,
		paramtype = "light",
		sunlight_propagates = true,
		buildable_to = true,
		walkable = false,
		pointable = pointable_compat,
		groups = {catchable = 1},
		selection_box = {
			type = "fixed",
			fixed = {-0.1, -0.1, -0.1, 0.1, 0.1, 0.1},
		},
		floodable = true,
		on_construct = function(pos)
			minetest.get_node_timer(pos):start(1)
		end,
		on_timer = function(pos, elapsed)
			if minetest.get_node_light(pos) < 11 then
				minetest.set_node(pos, {name = "butterflies:hidden_butterfly_"..name})
			end
			minetest.get_node_timer(pos):start(30)
		end
	})

	minetest.register_node("butterflies:hidden_butterfly_"..name, {
		drawtype = "airlike",
		inventory_image = "butterflies_butterfly_"..name..".png^default_invisible_node_overlay.png",
		wield_image =  "butterflies_butterfly_"..name..".png^default_invisible_node_overlay.png",
		paramtype = "light",
		sunlight_propagates = true,
		walkable = false,
		pointable = false,
		diggable = false,
		drop = "",
		groups = {not_in_creative_inventory = 1},
		floodable = true,
		on_construct = function(pos)
			minetest.get_node_timer(pos):start(1)
		end,
		on_timer = function(pos, elapsed)
			if minetest.get_node_light(pos) >= 11 then
				minetest.set_node(pos, {name = "butterflies:butterfly_"..name})
			end
			minetest.get_node_timer(pos):start(30)
		end
	})
end

-- register decoration
minetest.register_decoration({
	name = "butterflies:butterfly",
	deco_type = "simple",
	place_on = {"default:dirt_with_grass"},
	place_offset_y = 2,
	sidelen = 80,
	fill_ratio = 0.005,
	biomes = {"grassland", "deciduous_forest"},
	y_max = 31000,
	y_min = 1,
	decoration = {
		"butterflies:butterfly_white",
		"butterflies:butterfly_red",
		"butterflies:butterfly_violet"
	},
	spawn_by = "group:flower",
	num_spawn_by = 1
})

-- get decoration ID
local butterflies = minetest.get_decoration_id("butterflies:butterfly")
minetest.set_gen_notify({decoration = true}, {butterflies})

-- start nodetimers
minetest.register_on_generated(function(minp, maxp, blockseed)
	local gennotify = minetest.get_mapgen_object("gennotify")
	local poslist = {}

	for _, pos in ipairs(gennotify["decoration#"..butterflies] or {}) do
		local deco_pos = {x = pos.x, y = pos.y + 3, z = pos.z}
		table.insert(poslist, deco_pos)
	end

	if #poslist ~= 0 then
		for i = 1, #poslist do
			local pos = poslist[i]
			minetest.get_node_timer(pos):start(1)
		end
	end
end)
