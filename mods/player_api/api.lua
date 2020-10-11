player_api = {}

-- Player animation blending
-- Note: This is currently broken due to a bug in Irrlicht, leave at 0
local animation_blend = 0

player_api.registered_models = {}

-- Local for speed.
local models = player_api.registered_models

local function collisionbox_equals(collisionbox, other_collisionbox)
	if collisionbox == other_collisionbox then
		return true
	end
	for index = 1, 6 do
		if collisionbox[index] ~= other_collisionbox[index] then
			return false
		end
	end
	return true
end

function player_api.register_model(name, def)
	models[name] = def
	def.visual_size = def.visual_size or {x = 1, y = 1}
	def.collisionbox = def.collisionbox or {-0.3, 0.0, -0.3, 0.3, 1.7, 0.3}
	def.stepheight = def.stepheight or 0.6
	def.eye_height = def.eye_height or 1.47
	for animation_name, animation in pairs(def.animations) do
		animation.eye_height = animation.eye_height or def.eye_height
		animation.collisionbox = animation.collisionbox or def.collisionbox
		for _, other_animation in pairs(def.animations) do
			if other_animation._equals then
				if collisionbox_equals(animation.collisionbox, other_animation.collisionbox)
						and animation.eye_height == other_animation.eye_height then
					animation._equals = other_animation._equals
					break
				end
			end
		end
		animation._equals = animation._equals or animation_name
	end
end

-- Player stats and animations
-- model, textures, animation
local players = {}
player_api.player_attached = {}

local function get_player_data(player)
	return assert(players[player:get_player_name()], "offline_player")
end

function player_api.get_animation(player)
	return get_player_data(player)
end

-- Called when a player's appearance needs to be updated
function player_api.set_model(player, model_name)
	local player_data = get_player_data(player)
	if player_data.model == model_name then
		return
	end
	local model = models[model_name]
	if model then
		player:set_properties({
			mesh = model_name,
			textures = player_data.textures or model.textures,
			visual = "mesh",
			visual_size = model.visual_size,
			stepheight = model.stepheight
		})
		local animations = model.animations
		player:set_local_animation(
			animations.stand,
			animations.walk,
			animations.mine,
			animations.walk_mine,
			model.animation_speed or 30
		)
		-- sets collisionbox & eye_height
		player_api.set_animation(player, "stand")
	else
		player:set_properties({
			textures = {"player.png", "player_back.png"},
			visual = "upright_sprite",
			visual_size = {x = 1, y = 2},
			collisionbox = {-0.3, 0.0, -0.3, 0.3, 1.75, 0.3},
			stepheight = 0.6,
			eye_height = 1.625,
		})
	end
	player_data.model = model_name
end

function player_api.set_textures(player, textures)
	local player_data = get_player_data(player)
	local model = models[player_data.model]
	local new_textures = model and model.textures or textures
	player_data.textures = new_textures
	player:set_properties({textures = new_textures})
end

function player_api.set_animation(player, anim_name, speed)
	local player_data = get_player_data(player)
	local model = models[player_data.model]
	if not (model and model.animations[anim_name]) then
		return
	end
	speed = speed or model.animation_speed
	if player_data.animation == anim_name and player_data.animation_speed == speed then
		return
	end
	local previous_anim_equals = (model.animations[player_data.animation] or {})._equals
	local anim = model.animations[anim_name]
	player_data.animation = anim_name
	player_data.animation_speed = speed
	player:set_animation(anim, speed, animation_blend)
	if anim._equals == previous_anim_equals then
		player:set_properties({
			collisionbox = anim.collisionbox,
			eye_height = anim.eye_height
		})
	end
end

minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	players[name] = {}
	player_api.player_attached[name] = false
end)

minetest.register_on_leaveplayer(function(player)
	local name = player:get_player_name()
	players[name] = nil
	player_api.player_attached[name] = nil
end)

-- Localize for better performance.
local player_set_animation = player_api.set_animation
local player_attached = player_api.player_attached

-- Prevent knockback for attached players
local old_calculate_knockback = minetest.calculate_knockback
function minetest.calculate_knockback(player, ...)
	if player_attached[player:get_player_name()] then
		return 0
	end
	return old_calculate_knockback(player, ...)
end

-- Check each player and apply animations
minetest.register_globalstep(function()
	for _, player in pairs(minetest.get_connected_players()) do
		local name = player:get_player_name()
		local player_data = players[name]
		local model = models[player_data.model]
		if model and not player_attached[name] then
			local controls = player:get_player_control()
			local animation_speed_mod = model.animation_speed or 30

			-- Determine if the player is sneaking, and reduce animation speed if so
			if controls.sneak then
				animation_speed_mod = animation_speed_mod / 2
			end

			-- Apply animations based on what the player is doing
			if player:get_hp() == 0 then
				player_set_animation(player, "lay")
			elseif controls.up or controls.down or controls.left or controls.right then
				if controls.LMB or controls.RMB then
					player_set_animation(player, "walk_mine", animation_speed_mod)
				else
					player_set_animation(player, "walk", animation_speed_mod)
				end
			elseif controls.LMB or controls.RMB then
				player_set_animation(player, "mine", animation_speed_mod)
			else
				player_set_animation(player, "stand", animation_speed_mod)
			end
		end
	end
end)

-- HACK for keeping backwards compatibility
for _, api_function in pairs({"get_animation", "set_animation", "set_model", "set_textures"}) do
	local original_function = player_api[api_function]
	player_api[api_function] = function(...)
		local arguments = {...}
		local ret -- single value works because get_animation returns only one value
		local status, err = pcall(function()
			ret = original_function(unpack(arguments))
		end)
		if not status then
			if err == "offline_player" then
				minetest.log("warning", api_function .. " called on offline player")
				return
			end
			error(err)
		end
		return ret
	end
end