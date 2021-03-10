
--
-- InvList
--

local function assert_invlist_index(index, size)
	assert(type(index) == "number" and math.floor(index) == index, "InvList:set_stack: Invalid InvList stack index")
	assert(index > 0, "InvList:set_stack: InvList stack index should never be less than 1")
	assert(index <= size, "InvList:set_stack: Invalid InvList stack index larger than InvList size")
end

local InvList = {}
InvList.__index = InvList

function InvList:set_size(size)
	assert(size >= 0, "InvList:set_size: Negative size not acceptable")
	if size < #self then
		for i = #self, size + 1, -1 do
			table.remove(self, i)
		end
	end
	for i = 1, size do
		if not self[i] then
			self[i] = ItemStack()
		end
	end
end

function InvList:get_size()
	return #self
end

function InvList:get_count()
	return self._count
end

function InvList:is_empty()
	return self:get_count() < 1
end

function InvList:get_stack(index)
	assert_invlist_index(index, self:get_size())
	return ItemStack(self[index])
end

function InvList:set_stack(index, itemstack)
	assert_invlist_index(index, self:get_size())
	local stack = ItemStack(itemstack)
	local self_empty = self[index]:is_empty()
	local stack_empty = stack:is_empty()
	if self_empty and not stack_empty then
		-- Increment counter if adding new stack that is not empty
		self._count = self._count + 1
	elseif stack_empty and not self_empty then
		-- Decrement counter if replacing existing stack with empty stack
		self._count = self._count - 1
	end
	self[index] = stack
end

function InvList:add_stack(itemstack)
	if not ItemStack(itemstack):is_empty() then
		for index = 1, self:get_size() do
			if self[index]:is_empty() then
				-- Empty slot found
				self:set_stack(index, itemstack)
				return true
			elseif self[index]:item_fits(itemstack) then
				-- Slot with enough space found
				self[index]:add_item(itemstack)
				return true
			end
		end
	end
end

function InvList:__tostring()
	local items = {}
	for _, item in ipairs(self) do
		table.insert(items, tostring(item))
	end
	return ('InvList({%s}, %d, %d)'):format(table.concat(items, ","), self:get_count(), self:get_size())
end

mineunit.export_object(InvList, {
	private = true,
	name = "InvList",
	constructor = function(self, value)
		local obj = {
			_count = 0,
		}
		setmetatable(obj, InvList)
		if mineunit.utils.type(value) == "InvList" or type(value) == "table" then
			obj:set_size(#value)
			for _, stack in ipairs(value) do
				obj:add_stack(stack)
			end
		elseif value ~= nil then
			error("TYPE NOT IMPLEMENTED: " .. type(value))
		end
		return obj
	end
})

--
-- InvRef
--

local InvRef = {}
-- * `is_empty(listname)`: return `true` if list is empty
function InvRef:is_empty(listname)
	return (not self._lists[listname]) or self._lists[listname]:is_empty()
end
-- * `get_size(listname)`: get size of a list
function InvRef:get_size(listname)
	return self._lists[listname] and self._lists[listname]:get_size() or 0
end
-- * `set_size(listname, size)`: set size of a list
--    * returns `false` on error (e.g. invalid `listname` or `size`)
function InvRef:set_size(listname, size)
	if size and size == tonumber(size) then
		if not self._lists[listname] then
			self._lists[listname] = InvList()
		end
		self._lists[listname]:set_size(size)
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
	local list = self:get_list(listname)
	assert(list, "InvRef:set_stack: Invalid inventory list " .. tostring(list))
	return list:get_stack(i)
end
-- * `set_stack(listname, i, stack)`: copy `stack` to index `i` in list
function InvRef:set_stack(listname, i, stack)
	local list = self:get_list(listname)
	assert(list, "InvRef:set_stack: Invalid inventory list " .. tostring(list))
	list:set_stack(i, stack)
end
-- * `get_list(listname)`: return full list
function InvRef:get_list(listname)
	mineunit:warning("InvRef:get_list returning list "..listname.." as reference, this can lead to unxpected results")
	return self._lists[listname]
end
-- * `set_list(listname, list)`: set full list (size will not change)
function InvRef:set_list(listname, list)
	assert.is_string(listname, "InvRef:set_list expected `listname` to be string, got "..type(listname))
	assert.is_table(list, "InvRef:set_list expected `list` to be table, got " .. type(list))
	self._lists[listname] = InvList(list)
end
-- * `get_lists()`: returns list of inventory lists
function InvRef:get_lists()
	local results = {}
	for listname,_ in pairs(self._lists) do
		table.insert(results, listname)
	end
	return results
end
-- * `set_lists(lists)`: sets inventory lists (size will not change)
function InvRef:set_lists(lists)
	error("NOT IMPLEMENTED")
end
-- * `add_item(listname, stack)`: add item somewhere in list, returns leftover
function InvRef:add_item(listname, stack)
	local list = self:get_list(listname)
	assert(list, "InvRef:set_stack: Invalid inventory list " .. tostring(list))
	list:add_stack(stack)
end
-- * `room_for_item(listname, stack)`: returns `true` if the stack of items can be fully added to the list
function InvRef:room_for_item(listname, stack)
	for _, slot in ipairs(self:get_list(listname)) do
		if slot:item_fits(stack) then
			return true
		end
	end
	return false
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
		elseif mineunit.utils.type(value) == "InvRef" then
			obj = table.copy(value)
		else
			error("TYPE NOT IMPLEMENTED: " .. type(value))
		end
		obj._lists = obj._lists or {}
		setmetatable(obj, InvRef)
		return obj
	end,
})

--
-- MetaDataRef
--

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
		elseif mineunit.utils.type(value) == "MetaDataRef" then
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

--
-- NodeMetaRef
--

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
