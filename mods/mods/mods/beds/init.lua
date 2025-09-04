-- beds/init.lua

-- Load support for MT game translation.
local S = minetest.get_translator("beds")
local esc = minetest.formspec_escape

beds = {}
beds.player = {}
beds.bed_position = {}
beds.pos = {}
beds.spawn = {}
beds.get_translator = S

beds.formspec = "size[8,11;true]" ..
	"no_prepend[]" ..
	"bgcolor[#080808BB;true]" ..
	"button_exit[2,10;4,0.75;leave;" .. esc(S("Leave Bed")) .. "]"

beds.day_interval = {
	start = 0.2,
	finish = 0.805,
}

local modpath = minetest.get_modpath("beds")

-- Load files

dofile(modpath .. "/functions.lua")
dofile(modpath .. "/api.lua")
dofile(modpath .. "/beds.lua")
dofile(modpath .. "/spawns.lua")
