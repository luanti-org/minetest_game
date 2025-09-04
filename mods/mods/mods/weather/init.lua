-- Always load the API
dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/api.lua")

-- Disable by mapgen or setting

if minetest.settings:get_bool("enable_weather") == false then
	return
end

local mg_name = minetest.get_mapgen_setting("mg_name")
if mg_name == "v6" or mg_name == "singlenode" then
	-- set a default shadow intensity for mgv6 and singlenode
	minetest.register_on_joinplayer(function(player)
		player:set_lighting({
			shadows = { intensity = 0.33 },
			bloom = { intensity = 0.05 },
			volumetric_light = { strength = 0.2 },
		})
	end)

	return
end

-- Default implementation for noise based cloud appearance

local TSCALE = 600 -- Time scale of noise variation in seconds

local np_density = {
	offset = 0.5,
	scale = 0.5,
	spread = {x = TSCALE, y = TSCALE, z = TSCALE},
	seed = 813,
	octaves = 1,
	persist = 0,
	lacunarity = 2,
}

local np_thickness = {
	offset = 0.5,
	scale = 0.5,
	spread = {x = TSCALE, y = TSCALE, z = TSCALE},
	seed = 96,
	octaves = 1,
	persist = 0,
	lacunarity = 2,
}

local np_speedx = {
	offset = 0,
	scale = 1,
	spread = {x = TSCALE, y = TSCALE, z = TSCALE},
	seed = 911923,
	octaves = 1,
	persist = 0,
	lacunarity = 2,
}

local np_speedz = {
	offset = 0,
	scale = 1,
	spread = {x = TSCALE, y = TSCALE, z = TSCALE},
	seed = 5728,
	octaves = 1,
	persist = 0,
	lacunarity = 2,
}

local nobj_density = nil
local nobj_thickness = nil
local nobj_speedx = nil
local nobj_speedz = nil

local function rangelim(value, lower, upper)
	return math.min(math.max(value, lower), upper)
end

local t_offset
do
	local meta = minetest.get_mod_storage()
	if meta:contains("time_offset") then
		t_offset = meta:get_int("time_offset")
	else
		-- Use random offset so not each new world behaves the same.
		t_offset = math.random(0, 300000)
		meta:set_int("time_offset", t_offset)
	end
end

function weather.get(player)
	-- Adjusted time in seconds
	local time = math.floor(minetest.get_gametime() - t_offset)

	nobj_density = nobj_density or minetest.get_perlin(np_density)
	nobj_thickness = nobj_thickness or minetest.get_perlin(np_thickness)
	nobj_speedx = nobj_speedx or minetest.get_perlin(np_speedx)
	nobj_speedz = nobj_speedz or minetest.get_perlin(np_speedz)

	local n_density = nobj_density:get_2d({x = time, y = 0}) -- 0 to 1
	local n_thickness = nobj_thickness:get_2d({x = time, y = 0}) -- 0 to 1
	local n_speedx = nobj_speedx:get_2d({x = time, y = 0}) -- -1 to 1
	local n_speedz = nobj_speedz:get_2d({x = time, y = 0}) -- -1 to 1

	-- Fallback to mid-value 50 for very old worlds
	local humid = minetest.get_humidity(player:get_pos()) or 50
	-- Default and classic density value is 0.4, make this happen
	-- at humidity midvalue 50 when n_density is at midvalue 0.5.
	-- density_max = 0.25 at humid = 0.
	-- density_max = 0.8 at humid = 50.
	-- density_max = 1.35 at humid = 100.
	local density_max = 0.8 + ((humid - 50) / 50) * 0.55
	-- Range limit density_max to always have occasional
	-- small scattered clouds at extreme low humidity.
	local density = rangelim(density_max, 0.2, 1.0) * n_density

	return {
		clouds = {
			density = density,
			thickness = math.max(math.floor(
				rangelim(32 * humid / 100, 8, 32) * n_thickness
				), 2),
			speed = {x = n_speedx * 4, z = n_speedz * 4},
		},
		lighting = {
			shadows = { intensity = 0.7 * (1 - density) },
			bloom = { intensity = 0.05 },
			volumetric_light = { strength = 0.2 },
		}
	}
end
