
mineunit("common/serialize")
mineunit("metadata")

local ItemStack = {}
--* `is_empty()`: returns `true` if stack is empty.
function ItemStack:is_empty() return self._count < 1 end
--* `get_name()`: returns item name (e.g. `"default:stone"`).
function ItemStack:get_name() return self._count > 0 and self._name or "" end
--* `set_name(item_name)`: returns a boolean indicating whether the item was cleared.
function ItemStack:set_name(item_name)
	assert.is_string(item_name, "ItemStack:set_name expected item_name to be string")
	self._name = item_name
	if item_name == "" then
		self:set_count(0)
		return true
	end
	return false
end
--* `get_count()`: Returns number of items on the stack.
function ItemStack:get_count() return self._count end
--* `set_count(count)`: returns a boolean indicating whether the item was cleared
--    `count`: number, unsigned 16 bit integer
function ItemStack:set_count(count) self._count = count end
--* `get_wear()`: returns tool wear (`0`-`65535`), `0` for non-tools.
function ItemStack:get_wear() return self._wear end
--* `set_wear(wear)`: returns boolean indicating whether item was cleared
--    `wear`: number, unsigned 16 bit integer
function ItemStack:set_wear(wear)
	assert(wear <= 65535, "ItemStack:set_wear invalid wear value: "..tostring(wear))
	wear = wear < 0 and -((-wear) % 65536) or wear
	self._wear = math.max(0, wear < 0 and 65536 + wear or wear)
end
--* `get_meta()`: returns ItemStackMetaRef. See section for more details
function ItemStack:get_meta() return self._meta end
--* `get_metadata()`: (DEPRECATED) Returns metadata (a string attached to an item stack).
function ItemStack:get_metadata()
	mineunit:DEPRECATED("Using deprecated ItemStack:get_metadata()")
	return self:get_meta():get("")
end
--* `set_metadata(metadata)`: (DEPRECATED) Returns true.
function ItemStack:set_metadata(metadata)
	mineunit:DEPRECATED("Using deprecated ItemStack:set_metadata(metadata)")
	self:get_meta():set_string("", metadata)
	return true
end
--* `get_description()`: returns the description shown in inventory list tooltips.
--    The engine uses the same as this function for item descriptions.
--    Fields for finding the description, in order:
--        `description` in item metadata (See [Item Metadata].)
--        `description` in item definition
--        item name
function ItemStack:get_description()
	local value = self:get_meta():get("description")
	if value then return value end
	return self:get_definition().description
end
--* `get_short_description()`: returns the short description.
--    Unlike the description, this does not include new lines.
--    The engine uses the same as this function for short item descriptions.
--    Fields for finding the short description, in order:
--        `short_description` in item metadata (See [Item Metadata].)
--        `short_description` in item definition
--        first line of the description (See `get_description()`.)
function ItemStack:get_short_description()
	local value = self:get_meta():get("short_description")
	if value then return value end
	value = self:get_definition().short_description
	if value then return value end
	value = self:get_description()
	if value then return value:gmatch("[^\r\n]+")() end
end
--* `clear()`: removes all items from the stack, making it empty.
function ItemStack:clear() self._count = 0 end
--* `replace(item)`: replace the contents of this stack.
--    `item` can also be an itemstring or table.
function ItemStack:replace(item)
	local stack = mineunit.utils.type(item) == "ItemStack" and item or ItemStack(item)
	self._name = stack._name
	self._count = stack._count
	self._wear = stack._wear
	self._meta = stack._meta
end
--* `to_string()`: returns the stack in itemstring form.
-- https://github.com/minetest/minetest/blob/5.4.0/src/inventory.cpp#L59-L85
function ItemStack:to_string()
	if self:is_empty() then
		return ""
	elseif next(self:get_meta()._data) then
		local meta = self:get_meta():to_table().fields
		return ("%s %d %d %s"):format(self:get_name(), self:get_count(), self:get_wear(), core.serialize(meta))
	elseif self:get_wear() ~= 0 then
		return ("%s %d %d"):format(self:get_name(), self:get_count(), self:get_wear())
	elseif self:get_count() ~= 1 then
		return ("%s %d"):format(self:get_name(), self:get_count())
	end
	return self:get_name()
end
--* `to_table()`: returns the stack in Lua table form.
function ItemStack:to_table()
	-- NOTE: `metadata` field is not and probably will not be here, engine does add it but it seems to be legacy thing.
	if self:get_count() > 0 then
		return {
			name = self:get_name(),
			count = self:get_count(),
			wear = self:get_wear(),
			meta = self:get_meta():to_table().fields,
		}
	end
end
--* `get_stack_max()`: returns the maximum size of the stack (depends on the item).
function ItemStack:get_stack_max()
	return self:is_known() and (self:get_definition().stack_max or 99) or 99
end
--* `get_free_space()`: returns `get_stack_max() - get_count()`.
function ItemStack:get_free_space()
	return self:get_stack_max() - self:get_count()
end
--* `is_known()`: returns `true` if the item name refers to a defined item type.
function ItemStack:is_known()
	return not not core.registered_items[self._name]
end
--* `get_definition()`: returns the item definition table.
function ItemStack:get_definition()
	return core.registered_items[self._name] or core.registered_items.unknown
end
--* `get_tool_capabilities()`: returns the digging properties of the item,
--    or those of the hand if none are defined for this item type.
function ItemStack:get_tool_capabilities()
	error("NOT IMPLEMENTED")
end
--* `add_wear(amount)`
--    Increases wear by `amount` if the item is a tool
--    `amount`: number, integer
function ItemStack:add_wear(amount)
	self:set_wear(self._wear + amount)
end
--* `add_item(item)`: returns leftover `ItemStack`
--    Put some item or stack onto this stack
function ItemStack:add_item(item)
	local leftover = ItemStack(item)
	if item:is_empty() then
		return leftover
	end
	if self:is_empty() then
		self:replace(leftover)
		leftover:set_count(0)
		return leftover
	end

	local stack_max = item:get_stack_max()
	local count = self:get_count()
	local space = stack_max - count
	if space > 0 and self:get_name() == leftover:get_name() then
		local input_count = leftover:get_count()
		if input_count > space then
			self:set_count(stack_max)
			leftover:set_count(input_count - space)
		else
			self:set_count(count + input_count)
			leftover:set_count(0)
		end
	end
	return leftover
end
--* `item_fits(item)`: returns `true` if item or stack can be fully added to this one.
function ItemStack:item_fits(item)
	if self:is_empty() or self:get_name() == "" then
		return true
	end
	local stack = ItemStack(item)
	if self:get_name() == stack:get_name() then
		return self:get_free_space() >= stack:get_count()
	end
	return false
end
--* `take_item(n)`: returns taken `ItemStack`
--    Take (and remove) up to `n` items from this stack
--    `n`: number, default: `1`
function ItemStack:take_item(n)
	n = math.min(self:get_count(), n or 1)
	self:set_count(self:get_count() - n)
	local stack = ItemStack(self)
	stack:set_count(n)
	return stack
end
--* `peek_item(n)`: returns taken `ItemStack`
--    Copy (don't remove) up to `n` items from this stack
--    `n`: number, default: `1`
function ItemStack:peek_item(n)
	n = n or 1
	assert(n >= 0, "ItemStack:peek_item negative count not acceptable")
	local res = ItemStack(self)
	res:set_count(math.max(0, math.min(self:get_count(), n)))
	return res
end

function ItemStack:__tostring()
	local count = self:get_count()
	return 'ItemStack("' .. self:get_name() .. (count > 1 and " "..count or "") .. '")'
end

-- TODO: Allows `same` assertions but in corner cases makes mod code to return true where engine would return false.
-- Requires either overriding luassert `same` (nice for users) or only allowing special assertions (not so nice).
function ItemStack:__eq(other)
	if mineunit.utils.type(other) == "ItemStack" then
		return self:get_name() == other:get_name()
			and self._count == other._count
			and self._wear == other._wear
			and self._meta == other._meta
	end
	return false
end

mineunit.export_object(ItemStack, {
	name = "ItemStack",
	constructor = function(self, ...)
		local obj
		local argc = select("#", ...)
		if argc == 0 then
			-- Calling without any args is compatible only with some engine versions, this should be error instead.
			-- Mineunit uses ItemStack() without any args internally, fix this.
			-- Many tests use ItemStack() without any args internally, fix this too.
			-- Add file path and line to make it easier to find problem source.
			local info = debug.getinfo(3)
			local src = ("%s:%d"):format(info.short_src, info.currentline)
			mineunit:warning("ItemStack() called without arguments, use ItemStack(nil) instead ("..src..")")
		end
		-- Read arguments
		assert(argc <= 1, "ItemStack(...) called with extra arguments, use exactly one argument")
		--assert(#args[1] > 0, "ItemStack() called, use ItemStack(nil) instead")
		local value = ({...})[1]
		if value == nil then
			obj = {}
		elseif type(value) == "string" then
			-- Error if there's only whitespace, TODO: Add for strict mode
			assert(value:find("%S"), 'ItemStack(x) called with questionable arguments, did you mean ItemStack(nil)?')
			local m = value:gmatch("%S+")
			obj = {
				-- This *should* fail if name is empty, do not "fix":
				_name = m():gsub("^:", ""),
				_count = (function(v) return v and tonumber(v) end)(m()),
				_wear = (function(v) return v and tonumber(v) end)(m()),
				_meta = MetaDataRef(m()),
			}
		elseif mineunit.utils.type(value) == "ItemStack" then
			obj = table.copy(value)
			obj._meta = MetaDataRef(value._meta)
		else
			error("NOT IMPLEMENTED: " .. type(value))
		end
		obj._count = obj._count or (obj._name and 1 or 0)
		obj._name = obj._name or ""
		obj._wear = obj._wear or 0
		obj._meta = obj._meta or MetaDataRef()
		setmetatable(obj, ItemStack)
		return obj
	end,
})
