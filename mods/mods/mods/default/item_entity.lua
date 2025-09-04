-- mods/default/item_entity.lua

local builtin_item = minetest.registered_entities["__builtin:item"]

-- strictly speaking none of this is part of the API, so do some checks
-- and if it looks wrong skip the modifications
if not builtin_item or type(builtin_item.set_item) ~= "function" or type(builtin_item.on_step) ~= "function" then
	minetest.log("warning", "Builtin item entity does not look as expected, skipping overrides.")
	return
end

local smoke_particles = {
	amount = 3,
	time = 0.1,
	minpos = vector.new(-0.1, -0.1, -0.1),
	maxpos = vector.new(0.1, 0.1, 0.1),
	minvel = vector.new(0, 2.5, 0),
	maxvel = vector.new(0, 2.5, 0),
	minacc = vector.new(-0.15, -0.02, -0.15),
	maxacc = vector.new(0.15, -0.01, 0.15),
	minexptime = 4,
	maxexptime = 6,
	minsize = 5,
	maxsize = 5,
	collisiondetection = true,
	texture = {
		name = "default_item_smoke.png"
	}
}
if minetest.features.particle_blend_clip then
	smoke_particles.texture.blend = "clip"
end

local item = {
	set_item = function(self, itemstring, ...)
		builtin_item.set_item(self, itemstring, ...)

		local stack = ItemStack(itemstring)
		local itemdef = minetest.registered_items[stack:get_name()]
		if itemdef and itemdef.groups.flammable ~= 0 then
			self.flammable = itemdef.groups.flammable
		end
	end,

	burn_up = function(self)
		-- disappear in a smoke puff
		local p = self.object:get_pos()
		self.object:remove()
		minetest.sound_play("default_item_smoke", {
			pos = p,
			gain = 1.0,
			max_hear_distance = 8,
		}, true)
		local ps = table.copy(smoke_particles)
		ps.minpos = vector.add(ps.minpos, p)
		ps.maxpos = vector.add(ps.maxpos, p)
		minetest.add_particlespawner(ps)
	end,

	on_step = function(self, dtime, ...)
		builtin_item.on_step(self, dtime, ...)

		if self.flammable then
			-- flammable, check for igniters every 10 s
			self.ignite_timer = (self.ignite_timer or 0) + dtime
			if self.ignite_timer > 10 then
				self.ignite_timer = 0

				local pos = self.object:get_pos()
				if pos == nil then
					return -- object already deleted
				end
				local node = minetest.get_node_or_nil(pos)
				if not node then
					return
				end

				-- Immediately burn up flammable items in lava
				if minetest.get_item_group(node.name, "lava") > 0 then
					self:burn_up()
				else
					--  otherwise there'll be a chance based on its igniter value
					local burn_chance = self.flammable
						* minetest.get_item_group(node.name, "igniter")
					if burn_chance > 0 and math.random(0, burn_chance) ~= 0 then
						self:burn_up()
					end
				end
			end
		end
	end,
}

-- set defined item as new __builtin:item, with the old one as fallback table
setmetatable(item, { __index = builtin_item })
minetest.register_entity(":__builtin:item", item)
