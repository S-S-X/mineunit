local world = {}
local world_default_node

-- TODO: Add some protection against direct node modifications, preferably with clear warning message
function world.clear()
	local nodes = {}
	setmetatable(nodes, {
		__index = function(self, key) return rawget(self, key) or world_default_node end,
		__newindex = function(self, key, node)
			local resolved = rawget(core.registered_aliases, node.name)
			if resolved then
				node = table.copy(node)
				node.name = resolved
			end
			-- TODO: Add option for stricter validation of nodes added to world
			--assert(core.registered_nodes[node.name], "Attempt to place invalid node: "..tostring(node.name))
			rawset(self, key, node)
		end,
	})
	world.nodes = nodes
end

world.clear()

-- Helper to execute callbacks
local function call(fn, ...)
	if type(fn) == "function" then
		return fn(...)
	end
end

local function create_node(node, defaults)
	node = type(node) == "table" and node or { name = node }
	return {
		name = node.name and node.name or (defaults and defaults.name),
		param2 = node.param2 and node.param2 or (defaults and defaults.param2 or 0),
	}
end

-- FIXME: Node metadata should be integrated with world layout to handle set_node and its friends
local worldmeta = {}
function _G.core.get_meta(pos)
	local nodeid = minetest.hash_node_position(pos)
	if not worldmeta[nodeid] then
		worldmeta[nodeid] = NodeMetaRef()
	end
	return worldmeta[nodeid]
end

-- FIXME: Should also execute other related callbacks
function world.on_dig(pos, node, digger)
	node = node or minetest.get_node(pos)
	local nodedef = minetest.registered_nodes[node.name]
	return nodedef and call(nodedef.on_dig, pos, node, digger) and true or false
end

function world.clear_meta(pos)
	if mineunit.destroy_nodetimer then
		mineunit:destroy_nodetimer(pos)
	end
	worldmeta[minetest.hash_node_position(pos)] = nil
end

-- Static pointed_thing
local function get_pointed_thing(pos, pointed_thing_type)
	return {
		type = pointed_thing_type or "node",
		above = {x=pos.x,y=pos.y+1,z=pos.z}, -- Pointing from above to downwards,
		under = {x=pos.x,y=pos.y,z=pos.z}, -- crosshair at protected node surface
	}
end

function world.set_default_node(node)
	world_default_node = node and create_node(node) or nil
end

function world.get_node(pos)
	return world.nodes[core.hash_node_position(vector.round(pos))]
end

-- set_node sets world node without place/dig callbacks
function world.set_node(pos, node)
	node = create_node(node)
	assert(type(node.name) == "string", "Invalid node name, expected string but got " .. tostring(node.name))
	local hash = minetest.hash_node_position(pos)
	local nodedef = core.registered_nodes[node.name]
	local oldnode = world.nodes[hash]
	local oldnodedef = oldnode and core.registered_nodes[oldnode.name]
	if oldnodedef then
		call(oldnodedef.on_destruct, pos)
	end
	world.clear_meta(pos)
	world.nodes[hash] = node
	if oldnodedef then
		call(oldnodedef.after_destruct, pos, oldnode)
	end
	if nodedef then
		call(nodedef.on_construct, pos)
	end
end

-- swap_node sets world node without any callbacks
function world.swap_node(pos, node)
	local hash = minetest.hash_node_position(pos)
	node = create_node(node, world.nodes[hash])
	assert(type(node.name) == "string", "Invalid node name, expected string but got " .. tostring(node.name))
	world.nodes[hash] = node
end

-- Called after constructing node when node was placed using
-- minetest.item_place_node / minetest.place_node.
-- If return true no item is taken from itemstack.
function world.place_node(pos, node, placer, itemstack, pointed_thing)
	node = create_node(node)
	world.set_node(pos, node)
	local nodedef = core.registered_nodes[node.name]
	assert(nodedef, "Invalid nodedef for " .. tostring(node.name))
	if nodedef.after_place_node then
		itemstack = itemstack or ItemStack(node.name .. " 1")
		pointed_thing = pointed_thing or get_pointed_thing(pos)
		call(nodedef.after_place_node, pos, placer, itemstack, pointed_thing)
	end
end

local function has_meta(pos)
	local node_id = minetest.hash_node_position(pos)
	if worldmeta[node_id] then
		-- FIXME: NodeMetaRef / MetaDataRef should have API for this
		if count(worldmeta[node_id]._data) > 0 then
			return true
		end
		local inv = get_meta(pos):get_inventory()
		local lists = inv:get_lists()
		for _, list in ipairs(lists) do
			if not inv:is_empty(list) then
				return true
			end
		end
	end
end

-- FIXME: Does not handle node groups at all, groups are completely ignored
function world.find_nodes_in_area(p1, p2, nodenames, grouped)
	assert.is_table(p1, "Invalid p1, table expected")
	assert.is_table(p2, "Invalid p2, table expected")
	local sx, sy, sz = math.min(p1.x, p2.x), math.min(p1.y, p2.y), math.min(p1.z, p2.z)
	local ex, ey, ez = math.max(p1.x, p2.x), math.max(p1.y, p2.y), math.max(p1.z, p2.z)
	assert((sx - ex) * (sy - ey) * (sz - ez) <= 4096000, "find_nodes_in_area area limit exceeded, see documentation")

	-- Create lookup table for nodenames
	local names = {}
	if type(nodenames) == "table" then
		for _, name in ipairs(nodenames) do
			names[name] = true
		end
	else
		names = { [nodenames] = true }
	end

	-- Find nodes
	if grouped then
		local results = {}
		for x = sx, ex do
			for y = sy, ey do
				for z = sz, ez do
					local pos = {x=x, y=y, z=z}
					local node = minetest.get_node_or_nil(pos)
					if node and node.name and names[node.name] then
						if not results[node.name] then
							results[node.name] = {}
						end
						table.insert(results[node.name], pos)
					end
				end
			end
		end
		return results
	else
		local positions = {}
		local counts = {}
		for x = sx, ex do
			for y = sy, ey do
				for z = sz, ez do
					local pos = {x=x, y=y, z=z}
					local node = minetest.get_node_or_nil(pos)
					if node and node.name and names[node.name] then
						table.insert(positions, pos)
						if not counts[node.name] then
							counts[node.name] = 1
						end
						counts[node.name] = counts[node.name] + 1
					end
				end
			end
		end
		return positions, counts
	end
	error("world.find_nodes_in_area unexpected error (yes, bug)")
end

function world.find_nodes_with_meta(p1, p2)
	assert.is_table(p1, "Invalid p1, table expected")
	assert.is_table(p2, "Invalid p2, table expected")
	local sx, sy, sz = math.min(p1.x, p2.x), math.min(p1.y, p2.y), math.min(p1.z, p2.z)
	local ex, ey, ez = math.max(p1.x, p2.x), math.max(p1.y, p2.y), math.max(p1.z, p2.z)
	local get_meta = minetest.get_meta
	local results = {}
	for x = sx, ex do
		for y = sy, ey do
			for z = sz, ez do
				local pos = {x=x, y=y, z=z}
				if has_meta(pos) then
					table.insert(results, pos)
				end
			end
		end
	end
	return results
end

function world.remove_node(pos)
	world.set_node(pos, {name="air"})
end

function world.layout(layout, offset)
	world.clear()
	world.add_layout(layout, offset)
end

local function get_layout_area(def, offset)
	local p1, p2
	if def.x and def.y and def.z then
		p1, p2 = def, def
	else
		p1, p2 = def[1], def[2]
	end
	local sx, sy, sz = math.min(p1.x, p2.x), math.min(p1.y, p2.y), math.min(p1.z, p2.z)
	local ex, ey, ez = math.max(p1.x, p2.x), math.max(p1.y, p2.y), math.max(p1.z, p2.z)
	p1 = {x=sx, y=sy, z=sz}
	p2 = {x=ex, y=ey, z=ez}
	if offset then
		p1 = vector.add(p1, offset)
		p2 = vector.add(p2, offset)
	end
	return p1, p2
end

function world.add_layout(layout, offset)
	for _, node in ipairs(layout) do
		local p1, p2 = get_layout_area(node[1], offset)
		for x = p1.x, p2.x do
			for y = p1.y, p2.y do
				for z = p1.z, p2.z do
					world.set_node({x=x, y=y, z=z}, {name=node[2], param2=0})
				end
			end
		end
	end
end

return world
