-- Minetest Game mod: bucket
-- See README.txt for licensing and other information.

-- Load support for MT game translation.
local S = minetest.get_translator("bucket")


minetest.register_alias("bucket", "bucket:bucket_empty")
minetest.register_alias("bucket_water", "bucket:bucket_water")
minetest.register_alias("bucket_lava", "bucket:bucket_lava")

minetest.register_craft({
	output = "bucket:bucket_empty 1",
	recipe = {
		{"default:steel_ingot", "", "default:steel_ingot"},
		{"", "default:steel_ingot", ""},
	}
})

bucket = {}
bucket.liquids = {}

local function check_protection(pos, name, text)
	if minetest.is_protected(pos, name) then
		minetest.log("action", (name ~= "" and name or "A mod")
			.. " tried to " .. text
			.. " at protected position "
			.. minetest.pos_to_string(pos)
			.. " with a bucket")
		minetest.record_protection_violation(pos, name)
		return true
	end
	return false
end

local function log_action(pos, name, action)
	minetest.log("action", (name ~= "" and name or "A mod")
		.. " " .. action .. " at " .. minetest.pos_to_string(pos) .. " with a bucket")
end

-- Register a new liquid
--    source = name of the source node
--    flowing = name of the flowing node
--    itemname = name of the new bucket item (or nil if liquid is not takeable)
--    inventory_image = texture of the new bucket item (ignored if itemname == nil)
--    name = text description of the bucket item
--    groups = (optional) groups of the bucket item, for example {water_bucket = 1}
--    force_renew = (optional) bool. Force the liquid source to renew if it has a
--                  source neighbour, even if defined as 'liquid_renewable = false'.
--                  Needed to avoid creating holes in sloping rivers.
-- This function can be called from any mod (that depends on bucket).
function bucket.register_liquid(source, flowing, itemname, inventory_image, name,
		groups, force_renew)
	local itemname_raw = itemname
	itemname = itemname and itemname:match("^:(.+)") or itemname
	bucket.liquids[source] = {
		source = source,
		flowing = flowing,
		itemname = itemname,
		force_renew = force_renew,
	}
	bucket.liquids[flowing] = bucket.liquids[source]

	if itemname ~= nil then
		minetest.register_craftitem(itemname_raw, {
			description = name,
			inventory_image = inventory_image,
			stack_max = 1,
			liquids_pointable = true,
			groups = groups,

			on_place = function(itemstack, user, pointed_thing)
				-- Must be pointing to node
				if pointed_thing.type ~= "node" then
					return
				end

				local node = minetest.get_node_or_nil(pointed_thing.under)
				local ndef = node and minetest.registered_nodes[node.name]

				-- Call on_rightclick if the pointed node defines it
				if ndef and ndef.on_rightclick and
						not (user and user:is_player() and
						user:get_player_control().sneak) then
					return ndef.on_rightclick(
						pointed_thing.under,
						node, user,
						itemstack)
				end

				local lpos

				-- Check if pointing to a buildable node
				if ndef and ndef.buildable_to then
					-- buildable; replace the node
					lpos = pointed_thing.under
				else
					-- not buildable to; place the liquid above
					-- check if the node above can be replaced

					lpos = pointed_thing.above
					node = minetest.get_node_or_nil(lpos)
					local above_ndef = node and minetest.registered_nodes[node.name]

					if not above_ndef or not above_ndef.buildable_to then
						-- do not remove the bucket with the liquid
						return itemstack
					end
				end

				local pname = user and user:get_player_name() or ""
				if check_protection(lpos, pname, "place "..source) then
					return
				end

				minetest.set_node(lpos, {name = source})
				log_action(lpos, pname, "placed " .. source)
				return ItemStack("bucket:bucket_empty")
			end
		})
	end
end

minetest.register_craftitem("bucket:bucket_empty", {
	description = S("Empty Bucket"),
	inventory_image = "bucket.png",
	groups = {tool = 1},
	liquids_pointable = true,
	on_use = function(itemstack, user, pointed_thing)
		if pointed_thing.type == "object" then
			pointed_thing.ref:punch(user, 1.0, { full_punch_interval=1.0 }, nil)
			return user:get_wielded_item()
		elseif pointed_thing.type ~= "node" then
			-- do nothing if it's neither object nor node
			return
		end
		-- Check if pointing to a liquid source
		local pos = pointed_thing.under
		local node = minetest.get_node(pos)
		local liquiddef = bucket.liquids[node.name]
		local item_count = user:get_wielded_item():get_count()

		if liquiddef ~= nil
		and liquiddef.itemname ~= nil
		and node.name == liquiddef.source then
			local pname = user:get_player_name()
			if check_protection(pos, pname, "take ".. node.name) then
				return
			end

			-- default set to return filled bucket
			local giving_back = liquiddef.itemname

			-- check if holding more than 1 empty bucket
			if item_count > 1 then

				-- if space in inventory add filled bucked, otherwise drop as item
				local inv = user:get_inventory()
				if inv:room_for_item("main", {name=liquiddef.itemname}) then
					inv:add_item("main", liquiddef.itemname)
				else
					local upos = user:get_pos()
					upos.y = math.floor(upos.y + 0.5)
					minetest.add_item(upos, liquiddef.itemname)
				end

				-- set to return empty buckets minus 1
				giving_back = "bucket:bucket_empty "..tostring(item_count-1)

			end

			-- force_renew requires a source neighbour
			local source_neighbor = false
			if liquiddef.force_renew then
				source_neighbor =
					minetest.find_node_near(pos, 1, liquiddef.source)
			end
			if source_neighbor and liquiddef.force_renew then
				log_action(pos, pname, "picked up " .. liquiddef.source .. " (force renewed)")
			else
				minetest.add_node(pos, {name = "air"})
				log_action(pos, pname, "picked up " .. liquiddef.source)
			end

			return ItemStack(giving_back)
		else
			-- non-liquid nodes will have their on_punch triggered
			local node_def = minetest.registered_nodes[node.name]
			if node_def then
				node_def.on_punch(pos, node, user, pointed_thing)
			end
			return user:get_wielded_item()
		end
	end,
})

bucket.register_liquid(
	"default:water_source",
	"default:water_flowing",
	"bucket:bucket_water",
	"bucket_water.png",
	S("Water Bucket"),
	{tool = 1, water_bucket = 1}
)

-- River water source is 'liquid_renewable = false' to avoid horizontal spread
-- of water sources in sloping rivers that can cause water to overflow
-- riverbanks and cause floods.
-- River water source is instead made renewable by the 'force renew' option
-- used here.

bucket.register_liquid(
	"default:river_water_source",
	"default:river_water_flowing",
	"bucket:bucket_river_water",
	"bucket_river_water.png",
	S("River Water Bucket"),
	{tool = 1, water_bucket = 1},
	true
)

bucket.register_liquid(
	"default:lava_source",
	"default:lava_flowing",
	"bucket:bucket_lava",
	"bucket_lava.png",
	S("Lava Bucket"),
	{tool = 1}
)

minetest.register_craft({
	type = "fuel",
	recipe = "bucket:bucket_lava",
	burntime = 60,
	replacements = {{"bucket:bucket_lava", "bucket:bucket_empty"}},
})

-- Register buckets as dungeon loot
if minetest.global_exists("dungeon_loot") then
	dungeon_loot.register({
		{name = "bucket:bucket_empty", chance = 0.55},
		-- water in deserts/ice or above ground, lava otherwise
		{name = "bucket:bucket_water", chance = 0.45,
			types = {"sandstone", "desert", "ice"}},
		{name = "bucket:bucket_water", chance = 0.45, y = {0, 32768},
			types = {"normal"}},
		{name = "bucket:bucket_lava", chance = 0.45, y = {-32768, -1},
			types = {"normal"}},
	})
end
