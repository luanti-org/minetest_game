-- carts/init.lua

-- Load support for MT game translation.
local S = minetest.get_translator("carts")

carts = {}
carts.modpath = minetest.get_modpath("carts")
carts.railparams = {}
carts.get_translator = S

-- Maximal speed of the cart in m/s (min = -1)
carts.speed_max = 7
-- Set to -1 to disable punching the cart from inside (min = -1)
carts.punch_speed_max = 5
-- Maximal distance for the path correction (for dtime peaks)
carts.path_distance_max = 3


dofile(carts.modpath.."/functions.lua")
dofile(carts.modpath.."/rails.lua")
dofile(carts.modpath.."/cart_entity.lua")

-- Register rails as dungeon loot
if minetest.global_exists("dungeon_loot") then
	dungeon_loot.register({
		name = "carts:rail", chance = 0.35, count = {1, 6}
	})
end
