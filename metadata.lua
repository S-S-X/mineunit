
mineunit("common/misc_helpers")

local function assert_invlist_index(index, size)
	assert(type(index) == "number" and math.floor(index) == index, "InvList:set_stack: Invalid InvList stack index")
	assert(index > 0, "InvList:set_stack: InvList stack index should never be less than 1")
	assert(index <= size, "InvList:set_stack: Invalid InvList stack index larger than InvList size")
end

-- TODO: This should be moved to mineunit.utils with configurable failure behavior
local function get_integer(value, msg)
	local number = tonumber(value)
	if number == nil then
		error(msg.."Expected number, got: "..tostring(value))
	elseif type(number) ~= "number" then
		mineunit:warning(msg.."Expected number, got: "..type(value))
	end
	local integer = math.floor(number)
	if number ~= integer then
		mineunit:warning(msg.."Expected integer, got: "..tostring(value))
	end
	return integer
end

local function invlist_tostring(list)
	local items = {}
	for _, item in ipairs(list) do
		table.insert(items, tostring(item))
	end
	return ('InvList({%s}, %d)'):format(table.concat(items, ","), #list)
end

--
-- InvRef
--

local InvRef = {}
-- * `is_empty(listname)`: return `true` if list is empty
function InvRef:is_empty(listname)
	assert.is_string(listname, "InvRef:is_empty listname must be string. Got "..type(listname))
	if self._empty[listname] ~= nil then
		return self._empty[listname]
	elseif self._lists[listname] then
		for _, stack in ipairs(self._lists[listname]) do
			if not stack:is_empty() then
				self._empty[listname] = false
				return false
			end
		end
		self._empty[listname] = true
	end
	return true
end
-- * `get_size(listname)`: get size of a list
function InvRef:get_size(listname)
	return self._sizes[listname] or 0
end
-- * `set_size(listname, size)`: set size of a list
--    * returns `false` on error (e.g. invalid `listname` or `size`)
function InvRef:set_size(listname, size)
	local newsize = get_integer(size, "InvRef:set_size: ")
	if newsize < 0 then
		mineunit:warning("InvRef:set_size: Invalid size: "..tostring(size))
		return false
	elseif newsize == 0 then
		self._lists[listname] = nil
		self._empty[listname] = nil
		newsize = nil
	elseif newsize == self._sizes[listname] then
		return true
	elseif not self._lists[listname] then
		self._lists[listname] = {}
		setmetatable(self._lists[listname], { __tostring = invlist_tostring })
		self._empty[listname] = true
		for index = 1, newsize do
			self._lists[listname][index] = ItemStack()
		end
	elseif newsize > self._sizes[listname] then
		for index = self._sizes[listname], newsize do
			self._lists[listname][index] = ItemStack()
		end
	elseif newsize < self._sizes[listname] then
		self._empty[listname] = self._empty[listname] and true or nil
		for index = self._sizes[listname], newsize, -1 do
			self._lists[listname][index] = nil
		end
	end
	self._sizes[listname] = newsize
	return true
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
function InvRef:get_stack(listname, index)
	local list = self:get_list(listname)
	assert(list, "InvRef:set_stack: Invalid inventory list " .. tostring(list))
	assert_invlist_index(index, self:get_size(listname))
	return list[index] and ItemStack(list[index]) or ItemStack()
end
-- * `set_stack(listname, i, stack)`: copy `stack` to index `i` in list
function InvRef:set_stack(listname, index, stack)
	local list = self._lists[listname]
	assert(list, "InvRef:set_stack: Invalid inventory list " .. tostring(list))
	assert_invlist_index(index, self._sizes[listname])
	-- Either clone or create itemstack, both cases are needed here. References should not be added to lists.
	stack = ItemStack(stack)
	local input_empty = stack:is_empty()
	local target_empty = self._empty[listname] or list[index]:is_empty()
	if input_empty and target_empty then
		-- Both input and target stacks are empty, skip inventory update
		return
	elseif not target_empty then
		if input_empty then
			self._empty[listname] = self._sizes[listname] == 1 and true or nil
		end
	elseif not input_empty then
		self._empty[listname] = false
	end
	list[index] = stack
end
-- * `get_list(listname)`: return full list
function InvRef:get_list(listname)
	if not self._lists[listname] then
		mineunit:warning("InvRef:get_list list not found: "..tostring(listname))
		return nil
	end
	local result = {}
	for index, stack in ipairs(self._lists[listname]) do
		result[index] = ItemStack(stack)
	end
	return result
end
-- * `set_list(listname, list)`: set full list (size will not change)
function InvRef:set_list(listname, list)
	assert.is_string(listname, "InvRef:set_list expected `listname` to be string, got "..type(listname))
	assert.is_table(list, "InvRef:set_list expected `list` to be table, got " .. type(list))
	assert.is_table(self._lists[listname], "InvRef:set_list list does not exist "..tostring(listname))
	assert.is_table(list, "InvRef:set_stack: Invalid inventory list " .. tostring(list))
	-- Update list if input or target contains anything
	if not self._empty[listname] or next(list) then
		local empty = true
		local target = self._lists[listname]
		for index = 1, self._sizes[listname] do
			-- Either clone or create itemstack, both cases are needed here. References should not be added to lists.
			local stack = ItemStack(list[index])
			if stack:is_empty() then
				if not target[index]:is_empty() then
					target[index] = stack
				end
			else
				empty = false
				target[index] = stack
			end
		end
		self._empty[listname] = empty
	end
end
-- * `get_lists()`: returns list of inventory lists
function InvRef:get_lists()
	local results = {}
	for listname,list in pairs(self._lists) do
		results[listname] = table.copy(list)
	end
	return results
end
-- * `set_lists(lists)`: sets inventory lists (size will not change)
function InvRef:set_lists(lists)
	for listname,list in pairs(lists) do
		self:set_list(listname, list)
	end
end
-- * `add_item(listname, stack)`: add item somewhere in list, returns leftover
function InvRef:add_item(listname, stack)
	stack = ItemStack(stack)
	if not stack:is_empty() then
		local list = self._lists[listname]
		local count = stack:get_count()
		assert(list, "InvRef:add_item: Invalid inventory list " .. tostring(listname))
		for index = 1, self:get_size(listname) do
			-- Try to add items into stack, get and check leftover stack
			stack = list[index]:add_item(stack)
			if stack:is_empty() then
				break
			end
		end
		if stack:get_count() < count then
			self._empty[listname] = false
		end
	end
	return stack
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
	local list = self:get_list(listname)
	assert(list, "InvRef:contains_item: Invalid inventory list " .. tostring(listname))
	stack = type(stack) == "string" and ItemStack(stack) or stack
	local name = stack:get_name()
	local count = stack:get_count()
	local meta1 = match_meta and stack:get_meta():to_table().fields or nil
	for _, liststack in ipairs(list) do
		if liststack:get_name() == name and liststack:get_count() >= count then
			if not match_meta then
				return true
			end
			local meta2 = liststack:get_meta():to_table().fields
			local fieldcount = 0
			local matching = true
			for k,v in pairs(meta1) do
				if not v == meta2[k] then
					matching = false
					break
				end
				fieldcount = fieldcount + 1
			end
			if matching and mineunit.utils.count(meta2) == fieldcount then
				return true
			end
		end
	end
	return false
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
			obj = {
				_lists = {},
				_sizes = {},
				_empty = {},
			}
		elseif mineunit.utils.type(value) == "InvRef" then
			obj = table.copy(value)
		else
			error("TYPE NOT IMPLEMENTED: " .. type(value))
		end
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
	value = (value ~= nil and value ~= "") and tostring(value) or nil
	if self._data[key] ~= value then
		self._data[key] = value
	end
end
function MetaDataRef:get_string(key) return self._data[key] or "" end
function MetaDataRef:set_int(key, value) self:set_string(key, math.floor(value)) end
function MetaDataRef:get_int(key) return math.floor(tonumber(self._data[key]) or 0) end
function MetaDataRef:set_float(key, value) self:set_string(key, value) end
function MetaDataRef:get_float(key) return tonumber(self._data[key]) or 0 end
function MetaDataRef:to_table()
	local fields = {}
	for key, value in pairs(self._data) do
		fields[key] = value
	end
	return { fields = fields }
end
function MetaDataRef:from_table(t)
	assert(type(t) == "table", "MetaDataRef:from_table expects table as argument")
	if t.fields then
		assert(type(t.fields) == "table", "MetaDataRef:from_table expects table fields to be table")
		self._data = table.copy(t.fields)
	end
end
function MetaDataRef:equals(other)
	return self:__eq(other)
end

-- TODO: Allows `same` assertions but in corner cases makes mod code to return true where engine would return false.
-- Requires either overriding luassert `same` (nice for users) or only allowing special assertions (not so nice).
function MetaDataRef:__eq(other)
	if mineunit.utils.type(other) == "MetaDataRef" then
		local fieldcount = 0
		for key, value in pairs(self._data) do
			if other._data[key] ~= value then
				return false
			end
			fieldcount = fieldcount + 1
		end
		return mineunit.utils.count(other._data) == fieldcount
	end
	return false
end

function MetaDataRef:_empty()
	for _ in pairs(self._data) do
		return false
	end
	return true
end

function MetaDataRef:_clear()
	for key in pairs(self._data) do
		self._data[key] = nil
	end
end

--[[
	serialize metadata, for use in itemstrings
	https://github.com/minetest/minetest/blob/0f25fa7af655b98fa401176a523f269c843d1943/src/itemstackmetadata.cpp#L61-L71
]]
local DESERIALIZE_START = "\x01"
local DESERIALIZE_KV_DELIM = "\x02"
local DESERIALIZE_PAIR_DELIM = "\x03"
function MetaDataRef:_serialize()
	local parts = {}
	table.insert(parts, DESERIALIZE_START)
	for k, v in pairs(self._data) do
		if k ~= "" or v ~= "" then
			table.insert(parts, k)
			table.insert(parts, DESERIALIZE_KV_DELIM)
			table.insert(parts, v)
			table.insert(parts, DESERIALIZE_PAIR_DELIM)
		end
	end

	return json.encode(table.concat(parts, ""))
end

--[[
	deserialize metadata, for use in itemstrings
	https://github.com/minetest/minetest/blob/0f25fa7af655b98fa401176a523f269c843d1943/src/itemstackmetadata.cpp#L73-L94
]]
function MetaDataRef:_deserialize(s)
	s = json.decode(s)
	self:_clear()

	local function find_next(i)
		if i > #s then
			return
		end
		local key_start = i
		while s:sub(i, i) ~= DESERIALIZE_KV_DELIM and i <= #s do
			i = i + 1
		end
		local key_end = i - 1
		i = i + 1
		local value_start = i
		while s:sub(i, i) ~= DESERIALIZE_PAIR_DELIM and i <= #s do
			i = i + 1
		end
		local value_end = i - 1
		i = i + 1
		return i, s:sub(key_start, key_end), s:sub(value_start, value_end)
	end

	if s:sub(1, 1) == DESERIALIZE_START then
		local key, value
		local i = 2
		while true do
			i, key, value = find_next(i)
			if i and key and value then
				self._data[key] = value
			else
				break
			end
		end
	else
		-- "BACKWARDS COMPATIBILITY"
		self._data[""] = s
	end
end

mineunit.export_object(MetaDataRef, {
	name = "MetaDataRef",
	constructor = function(self, value)
		local obj
		if value == nil then
			obj = {}
		elseif mineunit.utils.type(value) == "MetaDataRef" then
			obj = table.copy(value)
		elseif type(value) == "string" then
			local it = MetaDataRef()
			it:_deserialize(value)
			return it
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

function NodeMetaRef:to_table()
	local result = MetaDataRef.to_table(self)
	result.inventory = self:get_inventory():get_lists()
	return result
end

function NodeMetaRef:from_table(t)
	assert(type(t) == "table", "NodeMetaRef:from_table expects table as argument")
	if t.fields then
		MetaDataRef.from_table(self, t)
	end
	if t.inventory then
		assert(type(t.inventory) == "table", "NodeMetaRef:from_table expects table inventory to be table")
		local inv = self:get_inventory()
		for listname, list in pairs(t.inventory) do
			inv:set_size(listname, #list)
			inv:set_list(listname, list)
		end
	end
end

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
		obj._inventory = obj._inventory or InvRef()
		setmetatable(obj, NodeMetaRef)
		return obj
	end,
})
