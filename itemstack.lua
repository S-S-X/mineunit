
mineunit("metadata")

local ItemStack = {}
--* `is_empty()`: returns `true` if stack is empty.
function ItemStack:is_empty() return self._count < 1 end
--* `get_name()`: returns item name (e.g. `"default:stone"`).
function ItemStack:get_name() return self._name end
--* `set_name(item_name)`: returns a boolean indicating whether the item was cleared.
function ItemStack:set_name(item_name) self._name = item_name end
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
	self._wear = math.min(65535, math.max(0, wear))
end
--* `get_meta()`: returns ItemStackMetaRef. See section for more details
function ItemStack:get_meta() return self._meta end
--* `get_metadata()`: (DEPRECATED) Returns metadata (a string attached to an item stack).
function ItemStack:get_metadata() DEPRECATED("Using deprecated ItemStack:get_metadata()") end
--* `set_metadata(metadata)`: (DEPRECATED) Returns true.
function ItemStack:set_metadata(metadata) DEPRECATED("Using deprecated ItemStack:set_metadata(metadata)") end
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
	error("NOT IMPLEMENTED")
end
--* `to_string()`: returns the stack in itemstring form.
-- https://github.com/minetest/minetest/blob/5.4.0/src/inventory.cpp#L59-L85
function ItemStack:to_string()
	-- FIXME: Does not currently serialize metadata
	return ("%s %d %d"):format(
		self:get_name(),
		self:get_count(),
		self:get_wear()
	)
end
--* `to_table()`: returns the stack in Lua table form.
function ItemStack:to_table()
	error("NOT IMPLEMENTED")
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
	return not not minetest.registered_items[self._name]
end
--* `get_definition()`: returns the item definition table.
function ItemStack:get_definition()
	return minetest.registered_items[self._name] or {}
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
	error("NOT IMPLEMENTED")
end
--* `item_fits(item)`: returns `true` if item or stack can be fully added to this one.
function ItemStack:item_fits(item)
	error("NOT IMPLEMENTED")
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

mineunit.export_object(ItemStack, {
	name = "ItemStack",
	constructor = function(self, value)
		local obj
		if value == nil then
			obj = {}
		elseif type(value) == "string" then
			local m = value:gmatch("%S+")
			obj = {
				-- This *should* fail if name is empty, do not "fix":
				_name = m():gsub("^:", ""),
				_count = (function(v) return v and tonumber(v) end)(m()),
				_wear = (function(v) return v and tonumber(v) end)(m()),
				_meta = MetaDataRef(m()),
			}
		elseif type(value) == "table" then
			obj = table.copy(value)
			obj._meta = MetaDataRef(value._meta)
		else
			error("NOT IMPLEMENTED")
		end
		obj._name = obj._name or nil
		obj._count = obj._count or 0
		obj._wear = obj._wear or 0
		obj._meta = obj._meta or MetaDataRef()
		setmetatable(obj, ItemStack)
		return obj
	end,
})
