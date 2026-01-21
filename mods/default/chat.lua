-- mods/default/chat.lua

-- support for MT game translation.
local S = default.get_translator

local function match_old(privs)
	local ok = false
	for k, v in pairs(privs) do
		if k == "give" and v then
			ok = true
		elseif v then
			return false
		end
	end
	return ok
end

-- Change /pulverize and /clearinv to not require give, like it used to be
-- before Luanti 5.15
for _, cmd in ipairs({"pulverize", "clearinv"}) do
	local def = core.registered_chatcommands[cmd]
	if def then
		if match_old(def.privs) then
			core.override_chatcommand(cmd, {
				privs = {interact=true},
			})
		else
			minetest.log("info", "Privileges of command /" .. cmd .. " look modified, not overriding them.")
		end
	end
end

-- Revert description of 'give' privilege to what it was in Luanti 5.14
if core.registered_privileges["give"] then
	core.registered_privileges["give"].description = S("Can use /give and /giveme")
end
