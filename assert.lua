
local function round(value)
	return (value < 0) and math.ceil(value - 0.5) or math.floor(value + 0.5)
end

local function path(t, s, ignorefirst)
	local components = s:split(".")
	if ignorefirst then
		table.remove(components, 1)
	end
	for _,key in ipairs(components) do
		t = t[key]
	end
	return t
end

local function sequential(t)
	local p = 1
	for i,_ in pairs(t) do
		if i ~= p then return false end
		p = p + 1
	end
	return true
end

local function count(t)
	if type(t) == "table" or type(t) == "userdata" then
		local c = 0
		for a,b in pairs(t) do
			c = c + 1
		end
		return c
	end
	mineunit:warning("count(t)", "invalid value", type(t))
end

local function tabletype(t)
	if type(t) == "table" or type(t) == "userdata" then
		if count(t) == #t and sequential(t) then
			return "array"
		else
			return "hash"
		end
	end
	mineunit:warning("tabletype(t)", "invalid value", type(t))
end

local function in_array(value, t)
	for _, v in ipairs(t) do
		if v == value then
			return true
		end
	end
	return false
end

local coordinate_keys = {x=true, y=true, z=true}
local function is_coordinate(thing)
	if type(thing) == "table" then
		for k,v in pairs(thing) do
			if type(v) ~= "number" or not coordinate_keys[k] then
				return false
			end
		end
		return true
	end
	return false
end

-- Type overrides

local lua_type = type

local function mineunit_type(obj)
	return lua_type(obj) == "table" and lua_type(obj._mineunit_typename) == "string" and obj._mineunit_typename
end

function type(value)
	local typename = mineunit_type(value)
	if typename then
		return typename == "table" and "table" or "userdata"
	end
	return lua_type(value)
end

--
-- Mineunit luassert extensions
--

-- Patch spy.on method, see https://github.com/Olivine-Labs/luassert/pull/174
local spy = require('luassert.spy')
function spy.on(target_table, target_key)
	assert(target_table, "Invalid argument #1 for spy.on(target_table, target_key)")
	local s = spy.new(target_table[target_key])
	rawset(target_table, target_key, s)
	-- store original data
	s.target_table = target_table
	s.target_key = target_key
	return s
end

local assert = require('luassert.assert')
local say = require("say")

local function is_table(_,args) return lua_type(args[1]) == "table" end
say:set("assertion.is_table.negative", "Expected %s to be table")
assert:register("assertion", "is_table", is_table, "assertion.is_table.negative")

local function is_array(_,args) return tabletype(args[1]) == "array" end
say:set("assertion.is_indexed.negative", "Expected %s to be indexed array")
assert:register("assertion", "is_indexed", is_array, "assertion.is_indexed.negative")

local function is_hash(_,args) return tabletype(args[1]) == "hash" end
say:set("assertion.is_hashed.negative", "Expected %s to be hash table")
assert:register("assertion", "is_hashed", is_hash, "assertion.is_hashed.negative")

local function greaterthan(_,args) return args[1] > args[2] end
say:set("assertion.gt.negative", "Expected %s to be more than %s")
assert:register("assertion", "gt", greaterthan, "assertion.gt.negative")

local function lessthan(_,args) return args[1] < args[2] end
say:set("assertion.lt.negative", "Expected %s to be less than %s")
assert:register("assertion", "lt", lessthan, "assertion.lt.negative")

local function check_in_array(_,args) return in_array(args[1], args[2]) end
say:set("assertion.in_array.negative", "Expected %s to be in array %s")
assert:register("assertion", "in_array", check_in_array, "assertion.in_array.negative")

local function check_nodename(state,args)
	local msg = "Expected node %s at x=%d,y=%d,z=%d but found %s"
	local node = world.get_node(args[2])
	state.failure_message = msg:format(args[1], args[2].x, args[2].y, args[2].z, node and node.name or "nothing")
	return node and node.name == args[1]
end
assert:register("assertion", "nodename", check_nodename)

local function check_param2(_,args) return core.get_node(args[2]).param2 == args[1] end
say:set("assertion.param2.negative", "Expected param2 to be %s at %s")
assert:register("assertion", "param2", check_param2, "assertion.param2.negative")

local function close_enough(state, args)
	local msg = "Expected %s = %s to be %s"
	local a, b = args[1], type(args[2]) == "table" and path(args[2], args[3], true) or args[2]
	state.failure_message = msg:format(tostring(args[3]) or "input", tostring(a), tostring(b))
	return ((math.abs(a - b) * 1000000000) < 0.000001)
end
assert:register("assertion", "close_enough", close_enough)

say:set("assertion.is_coordinate.negative", "Expected %s to be valid coordinates")
assert:register("assertion", "is_coordinate", is_coordinate, "assertion.is_coordinate.negative")

-- TODO: Check this one, should it actually check for mineunit_type Player instead of tble or userdata
local function player_or_name(_,args)
	return (type(args[1]) == "string" and args[1] ~= "") or in_array(type(args[1]), {"table", "userdata"})
end
say:set("assertion.player_or_name.negative", "Expected %s to be player or name")
assert:register("assertion", "player_or_name", player_or_name, "assertion.player_or_name.negative")

local mineunit_types = {
	"ItemStack",
	"InvRef",
	"MetaDataRef",
	"NodeMetaRef",
	"Player"
}
for _, typename in ipairs(mineunit_types) do
	local assertname = "is_" .. typename
	local function checktype(_,args) return mineunit_type(args[1]) == typename end
	say:set("assertion."..assertname..".negative", "Expected %s to be "..typename)
	assert:register("assertion", assertname, checktype, "assertion."..assertname..".negative")
end

-- Inventory assertions

local function resolve_args_inv_list_slot_stack(a, b, c, d)
	if mineunit_type(a) == "Player" then
		inv = a:get_inventory()
	elseif is_coordinate(a) then
		inv = world.get_meta(a):get_inventory()
	else
		return
	end
	-- This makes some cases fail without error, those cases are not supported and it is invalid assertion use
	local stack = d or c or b or nil
	return inv, (c and b or nil), (d and c or nil), (type(stack) == "string" and ItemStack(stack) or stack)
end

local function formatname(thing)
	local mtype = mineunit_type(thing)
	if mtype == "Player" then
		return thing:get_player_name()
	elseif mtype == "ItemStack" then
		return thing:get_name()
	elseif is_coordinate(thing) then
		return pos.x..","..pos.y..","..pos.z
	elseif type(thing) == "string" then
		return thing
	end
	error("formatname: unsupported thing")
end

-- has_item(Player, listname, slotnumber, itemstring|ItemStack)
-- has_item(Player, listname, itemstring|ItemStack)
-- has_item(Player, itemstring|ItemStack)
-- has_item(coordinate, listname, slotnumber, itemstring|ItemStack)
-- has_item(coordinate, listname, itemstring|ItemStack)
-- has_item(coordinate, itemstring|ItemStack)
local function has_item(state, args)
	local inv, list, slot, expected = resolve_args_inv_list_slot_stack(args[1], args[2], args[3], args[4])
	assert.is_InvRef(inv, "assert.has_item expected Player or coordinates, got "..type(args[1]))
	assert(type(list) == "string" or list == nil, "Invalid 2nd argument for has_item assertion")
	assert(type(slot) == "number" or slot == nil, "Invalid 3rd argument for has_item assertion")
	assert.is_ItemStack(expected, "Invalid expected stack for has_item assertion")
	local msg = "Expected %s to have item %s"
	state.failure_message = msg:format(formatname(args[1]), tostring(expected))
	if list then
		if slot then
			local actual = inv:get_stack(list, slot)
			local msg = "Expected %s to have %s but found %s"
			state.failure_message = msg:format(formatname(args[1]), tostring(expected), tostring(actual))
			return actual:get_name() == expected:get_name() and actual:get_count() == expected:get_count()
		end
		return inv:contains_item(list, expected)
	end
	for listname in pairs(inv._lists) do
		if inv:contains_item(listname, expected) then
			return true
		end
	end
	return false
end
assert:register("assertion", "has_item", has_item)

-- Replace builtin assert with luassert

_G.assert = assert

-- TODO: Something wrong with this

return {
	sequential = sequential,
	count = count,
	tabletype = tabletype,
	round = round,
	is_coordinate = is_coordinate,
	has_item = has_item,
	type = mineunit_type
}
