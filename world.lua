local world = {
	nodes = {}
}

-- Helper to execute callbacks
local function call(fn, ...)
	if type(fn) == "function" then
		return fn(...)
	end
end

-- Static pointed_thing
local function get_pointed_thing(pos, pointed_thing_type)
	return {
		type = pointed_thing_type or "node",
		above = {x=pos.x,y=pos.y+1,z=pos.z}, -- Pointing from above to downwards,
		under = {x=pos.x,y=pos.y,z=pos.z}, -- crosshair at protected node surface
	}
end

-- set_node sets world node without callbacks
function world.set_node(pos, node)
	node = type(node) == "table" and node or { name = node, param2 = 0 }
	assert(type(node.name) == "string", "Invalid node name, expected string but got " .. tostring(node.name))
	local hash = minetest.hash_node_position(pos)
	world.nodes[hash] = node
	local nodedef = core.registered_nodes[node.name]
	if nodedef then
		call(nodedef.on_construct, pos)
	end
end

-- swap_node sets world node without callbacks
function world.swap_node(pos, node)
	local hash = minetest.hash_node_position(pos)
	node = type(node) == "table" and node or { name = node }
	node.param2 = world.nodes[hash] and world.nodes[hash].param2 or 0
	assert(type(node.name) == "string", "Invalid node name, expected string but got " .. tostring(node.name))
	world.nodes[hash] = node
end

-- Called after constructing node when node was placed using
-- minetest.item_place_node / minetest.place_node.
-- If return true no item is taken from itemstack.
function world.place_node(pos, node, placer, itemstack, pointed_thing)
	world.set_node(pos, node)
	local nodedef = core.registered_nodes[node.name]
	assert(nodedef, "Invalid nodedef for " .. tostring(node.name))
	if nodedef.after_place_node then
		itemstack = itemstack or ItemStack(node.name .. " 1")
		pointed_thing = pointed_thing or get_pointed_thing(pos)
		call(nodedef.after_place_node, pos, placer, itemstack, pointed_thing)
	end
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

function world.find_nodes_with_meta(p1, p2)
	assert.is_table(p1, "Invalid p1, table expected")
	assert.is_table(p2, "Invalid p2, table expected")
	local sx, sy, sz = math.min(p1.x, p2.x), math.min(p1.y, p2.y), math.min(p1.z, p2.z)
	local ex, ey, ez = math.max(p1.x, p2.x), math.max(p1.y, p2.y), math.max(p1.z, p2.z)
	local get_meta = minetest.get_meta
	local count = mineunit.utils.count
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

function world.clear()
	world.nodes = {}
end

function world.layout(layout, offset)
	world.clear()
	world.add_layout(layout, offset)
end

function world.add_layout(layout, offset)
	for _, node in ipairs(layout) do
		local pos = {
			x = node[1].x,
			y = node[1].y,
			z = node[1].z,
		}
		if offset then
			pos.x = pos.x + offset.x
			pos.y = pos.y + offset.y
			pos.z = pos.z + offset.z
		end
		_G.world.set_node(pos, {name=node[2], param2=0})
	end
end

return world
