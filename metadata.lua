
local InvRef = {}
-- * `is_empty(listname)`: return `true` if list is empty
function InvRef:is_empty(listname)
	error("NOT IMPLEMENTED")
end
-- * `get_size(listname)`: get size of a list
function InvRef:get_size(listname)
	error("NOT IMPLEMENTED")
end
-- * `set_size(listname, size)`: set size of a list
--    * returns `false` on error (e.g. invalid `listname` or `size`)
function InvRef:set_size(listname, size)
	if self._lists[listname] and size and size == tonumber(size) then
		self._lists[listname]._size = size
		return true
	end
	return false
end
-- * `get_width(listname)`: get width of a list
function InvRef:get_width(listname)
	error("NOT IMPLEMENTED")
end
-- * `set_width(listname, width)`: set width of list; currently used for crafting
function InvRef:set_width(listname, width)
	error("NOT IMPLEMENTED")
end
-- * `get_stack(listname, i)`: get a copy of stack index `i` in list
function InvRef:get_stack(listname, i)
	error("NOT IMPLEMENTED")
end
-- * `set_stack(listname, i, stack)`: copy `stack` to index `i` in list
function InvRef:set_stack(listname, i, stack)
	error("NOT IMPLEMENTED")
end
-- * `get_list(listname)`: return full list
function InvRef:get_list(listname)
	error("NOT IMPLEMENTED")
end
-- * `set_list(listname, list)`: set full list (size will not change)
function InvRef:set_list(listname, list)
	error("NOT IMPLEMENTED")
end
-- * `get_lists()`: returns list of inventory lists
function InvRef:get_lists()
	error("NOT IMPLEMENTED")
end
-- * `set_lists(lists)`: sets inventory lists (size will not change)
function InvRef:set_lists(lists)
	error("NOT IMPLEMENTED")
end
-- * `add_item(listname, stack)`: add item somewhere in list, returns leftover
function InvRef:add_item(listname, stack)
	error("NOT IMPLEMENTED")
end
-- * `room_for_item(listname, stack)`: returns `true` if the stack of items can be fully added to the list
function InvRef:room_for_item(listname, stack)
	error("NOT IMPLEMENTED")
end
-- * `contains_item(listname, stack, [match_meta])`: returns `true` if
--  the stack of items can be fully taken from the list.
--  If `match_meta` is false, only the items names are compared
--  (default: `false`).
function InvRef:contains_item(listname, stack, match_meta)
	error("NOT IMPLEMENTED")
end
-- * `remove_item(listname, stack)`: take as many items as specified from the
--  list, returns the items that were actually removed (as an `ItemStack`)
--  -- note that any item metadata is ignored, so attempting to remove a specific
--  unique item this way will likely remove the wrong one -- to do that use
--  `set_stack` with an empty `ItemStack`.
function InvRef:remove_item(listname, stack)
	error("NOT IMPLEMENTED")
end
-- * `get_location()`: returns a location compatible to
--  `minetest.get_inventory(location)`.
--    * returns `{type="undefined"}` in case location is not known
function InvRef:get_location()
	error("NOT IMPLEMENTED")
end

mineunit.export_object(InvRef, {
	name = "InvRef",
	constructor = function(self, value)
		local obj
		if value == nil then
			obj = {}
		elseif type(value) == "table" then
			obj = table.copy(value)
		else
			print(value)
			error("TYPE NOT IMPLEMENTED: " .. type(value))
		end
		obj._lists = obj._lists or {}
		setmetatable(obj, InvRef)
		return obj
	end,
})

local MetaDataRef = {}
function MetaDataRef:contains(key) return self._data[key] ~= nil end
function MetaDataRef:get(key) return self._data[key] end
function MetaDataRef:set_string(key, value)
	value = value ~= nil and tostring(value)
	self._data[key] = value ~= "" and value
end
function MetaDataRef:get_string(key) return self._data[key] or "" end
function MetaDataRef:set_int(key, value) self:set_string(key, math.floor(value)) end
function MetaDataRef:get_int(key) return math.floor(tonumber(self._data[key]) or 0) end
function MetaDataRef:set_float(key, value) self:set_string(key, value) end
function MetaDataRef:get_float(key) return tonumber(self._data[key]) or 0 end
function MetaDataRef:to_table() error("NOT IMPLEMENTED") end
function MetaDataRef:from_table(t) error("NOT IMPLEMENTED") end
function MetaDataRef:equals(other) error("NOT IMPLEMENTED") end

mineunit.export_object(MetaDataRef, {
	name = "MetaDataRef",
	constructor = function(self, value)
		local obj
		if value == nil then
			obj = {}
		elseif type(value) == "table" then
			obj = table.copy(value)
		else
			print(value)
			error("TYPE NOT IMPLEMENTED: " .. type(value))
		end
		obj._data = obj._data or {}
		setmetatable(obj, MetaDataRef)
		return obj
	end,
})

local NodeMetaRef = table.copy(MetaDataRef)
function NodeMetaRef:get_inventory() return self._inventory end
function NodeMetaRef:mark_as_private(...) mineunit:info("NodeMetaRef:mark_as_private", ...) end

mineunit.export_object(NodeMetaRef, {
	name = "NodeMetaRef",
	constructor = function(self, value)
		local obj
		if value == nil then
			obj = {}
		elseif type(value) == "table" then
			obj = table.copy(value)
		else
			print(value)
			error("TYPE NOT IMPLEMENTED: " .. type(value))
		end
		obj._data = obj._data or {}
		obj._inventory = InvRef()
		setmetatable(obj, NodeMetaRef)
		return obj
	end,
})

-- FIXME: Node metadata should be integrated with world layout to handle set_node and its friends
local worldmeta = {}
_G.minetest.get_meta = function(pos)
	local nodeid = minetest.hash_node_position(pos)
	if not worldmeta[nodeid] then
		worldmeta[nodeid] = NodeMetaRef()
	end
	return worldmeta[nodeid]
end
