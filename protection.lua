
mineunit("core")

local protected_nodes = {}

function mineunit:protect(pos, name)
	protected_nodes[minetest.hash_node_position(pos)] = name
end

minetest.is_protected = function(pos, name)
	local nodeid = minetest.hash_node_position(pos)
	if protected_nodes[nodeid] == nil or protected_nodes[nodeid] == name then
		return false
	end
	return true
end

minetest.record_protection_violation = function(...)
	print("minetest.record_protection_violation", ...)
end
