
mineunit("core")

local protected_nodes = {}

function mineunit:protect(pos, name_or_player)
	assert(type(name_or_player) == "string" or type(name_or_player) == "userdata",
		"mineunit:protect name_or_player should be string or userdata")
	local name = type(name_or_player) == "userdata" and name_or_player:get_player_name() or name_or_player
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
