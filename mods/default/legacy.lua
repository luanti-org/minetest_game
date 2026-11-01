-- mods/default/legacy.lua

function default.register_falling_node(nodename, texture)
	error("default.register_falling_node is obsolete")
end

function default.spawn_falling_node(p, nodename)
	error("default.spawn_falling_node is obsolete")
end

-- Liquids
WATER_ALPHA = minetest.registered_nodes["default:water_source"].alpha
WATER_VISC = minetest.registered_nodes["default:water_source"].liquid_viscosity
LAVA_VISC = minetest.registered_nodes["default:lava_source"].liquid_viscosity
LIGHT_MAX = default.LIGHT_MAX

-- Formspecs
default.gui_suvival_form = default.gui_survival_form
default.gui_bg     = ""
default.gui_bg_img = ""
default.gui_slots  = ""

-- Players
if minetest.get_modpath("player_api") then
	default.registered_player_models = player_api.registered_models
	default.player_register_model    = player_api.register_model
	default.player_attached          = player_api.player_attached
	default.player_get_animation     = player_api.get_animation
	default.player_set_model         = player_api.set_model
	default.player_set_textures      = player_api.set_textures
	default.player_set_animation     = player_api.set_animation
end

-- Chests
default.register_chest = default.chest.register_chest

-- Check for a volume intersecting protection
function default.intersects_protection(minp, maxp, player_name, interval)
	minetest.log("warning", "default.intersects_protection() is " ..
		"deprecated, use minetest.is_area_protected() instead.")
	return minetest.is_area_protected(minp, maxp, player_name, interval)
end
