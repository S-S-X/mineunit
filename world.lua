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
