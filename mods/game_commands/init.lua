-- game_commands/init.lua

-- Load support for MT game translation.
local S = core.get_translator("game_commands")


core.register_chatcommand("killme", {
	description = S("Kill yourself to respawn"),
	func = function(name)
		local player = core.get_player_by_name(name)
		if player then
			if core.settings:get_bool("enable_damage") then
				player:set_hp(0)
				return true
			else
				for _, callback in pairs(core.registered_on_respawnplayers) do
					if callback(player) then
						return true
					end
				end

				-- There doesn't seem to be a way to get a default spawn pos
				-- from the lua API
				return false, S("No static_spawnpoint defined")
			end
		else
			-- Show error message if used when not logged in, eg: from IRC mod
			return false, S("You need to be online to be killed!")
		end
	end
})
