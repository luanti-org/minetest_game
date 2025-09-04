--
-- Crafting recipes
--

minetest.register_craft({
	output = "keys:skeleton_key",
	recipe = {
		{"default:gold_ingot"},
	}
})

--
-- Cooking recipes
--

minetest.register_craft({
	type = "cooking",
	output = "default:gold_ingot",
	recipe = "keys:key",
	cooktime = 5,
})

minetest.register_craft({
	type = "cooking",
	output = "default:gold_ingot",
	recipe = "keys:skeleton_key",
	cooktime = 5,
})
