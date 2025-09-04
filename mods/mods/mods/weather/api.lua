local CYCLE = 8 -- Time period of cyclic clouds update in seconds

weather = {}

-- default implementation is empty
function weather.get(player)
	return {}
end

local function do_update()
	for _, player in ipairs(minetest.get_connected_players()) do
		local params = weather.get(player)
		assert(params ~= nil, "weather.get() must not return nil")
		if params.clouds then
			player:set_clouds(params.clouds)
		end
		if params.lighting then
			player:set_lighting(params.lighting)
		end
	end
end

local function cyclic_update()
	do_update()
	minetest.after(CYCLE, cyclic_update)
end
minetest.after(0, cyclic_update)

-- Update on player join to instantly alter clouds from the default
minetest.register_on_joinplayer(function(player)
	do_update()
end)
