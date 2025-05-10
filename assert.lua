
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
	--mineunit:warning("count(t)", "invalid value", type(t))
end

local function tabletype(t)
	if type(t) == "table" or type(t) == "userdata" then
		if count(t) == #t and sequential(t) then
			return "array"
		else
			return "hash"
		end
	end
	--mineunit:warning("tabletype(t)", "invalid value", type(t))
end

local function in_array(t, value)
	for i, v in ipairs(t) do
		if v == value then
			return i
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

local function format_coordinate(t)
	local result = {}
	for k in pairs(coordinate_keys) do
		table.insert(result, k .. "=" .. (rawget(t, k) or "nil"))
	end
	return "{" .. table.concat(result, ",") .. "}"
end

-- Type overrides

local lua_type = type

local function mineunit_type(obj)
	if lua_type(obj) == "table" then
		return rawget(obj, "_mineunit_typename")
	end
end

function type(value)
	local typename = mineunit_type(value)
	if typename then
		return typename == "table" and "table" or "userdata"
	end
	return lua_type(value)
end

--
-- Mineunit utilities
--

local function is_valid_name(name)
	return lua_type(name) == "string" and #name > 0 and #name < 21
		and name:find("[^abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789%-_]") == nil
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
local format_argument = require('luassert.state').format_argument
local say = require("say")

local function setmsg(state, msg)
	if lua_type(msg) == "string" then
		state.failure_message = msg
	end
end

local function fmtargs(argc, args)
	local results = {}
	for i = 1, argc do
		if args[i] == nil then
			results[i] = tostring(args[i])
		else
			local argtype = mineunit_type(args[i]) or lua_type(args[i]) or "<failed to get type>"
			results[i] = format_argument(args[i] or assert(tostring(args[i]), "invalid __tostring " .. argtype))
		end
	end
	return results
end

local function register(name, argc, msg, fn)
	local function wrapper(state, args)
		-- FIXME: Add internal assertion for args[argc + 1]. Not string == invalid assertion args.
		local failmsg = args[argc + 1] or msg
		if type(failmsg) == "string" then
			setmsg(state, failmsg:format(unpack(fmtargs(argc, args))))
		end
		return fn(args)
	end
	assert:register("assertion", name, wrapper, "assertion."..name..".negative")
end

register("table", 1, "Expected %s to be table", function(args)
	return lua_type(args[1]) == "table"
end)

register("indexed", 1, "Expected %s to be indexed array", function(args)
	return tabletype(args[1]) == "array"
end)

register("hashed", 1, "Expected %s to be hash table", function(args)
	return tabletype(args[1]) == "hash"
end)

register("integer", 1, "Expected %s to be integer", function(args)
	return type(args[1]) == "number" and args[1] == math.floor(args[1])
end)

register("gt", 2, "Expected %s to be more than %s", function(args)
	return args[1] > args[2]
end)

register("lt", 2, "Expected %s to be less than %s", function(args)
	return args[1] < args[2]
end)

register("in_array", 2, "Expected %s to be in array %s", function(args)
	return in_array(args[2], args[1])
end)

local function check_nodename(state,args)
	local msg = "Expected node %s at x=%d,y=%d,z=%d but found %s"
	local node = world.get_node(args[2])
	state.failure_message = msg:format(args[1], args[2].x, args[2].y, args[2].z, node and node.name or "nothing")
	return node and node.name == args[1]
end
assert:register("assertion", "nodename", check_nodename)

register("param2", 2, "Expected param2 to be %s at %s", function(args)
	return core.get_node(args[2]).param2 == args[1]
end)

local function close_enough(state, args)
	local msg = "Expected %s = %s to be %s"
	local a, b = args[1], type(args[2]) == "table" and path(args[2], args[3], true) or args[2]
	state.failure_message = msg:format(tostring(args[3]) or "input", tostring(a), tostring(b))
	return ((math.abs(a - b) * 1000000000) < 0.000001)
end
assert:register("assertion", "close_enough", close_enough)

say:set("assertion.is_coordinate.negative", "Expected %s to be valid coordinates")
assert:register("assertion", "is_coordinate", is_coordinate, "assertion.is_coordinate.negative")

-- TODO: Add configuration to allow relaxed requirements, very strict by default.
-- Not meant to allow empty string, not meant to allow registration prefix, only itemname or modname:itemname.
register("itemname", 1, "Expected %s to be valid item name", function(args)
	return type(args[1]) == "string" and #args[1] > 0 and (
		args[1]:match("^[%w_]+:[%w_]+$") or args[1]:match("^[%w_]+$")
	)
end)

register("itemstring", 1, "Expected %s to be valid item string", function(args)
	if type(args[1]) ~= "string" or #args[1] < 0 then
		return false
	end
	local stack = ItemStack(args[1])
	if mineunit_type(stack) ~= "ItemStack" then
		return false
	end
	local name = stack:get_name()
	return #name > 0 and (name:match("^[%w_]+:[%w_]+$") or name:match("^[%w_]+$"))
end)

register("player_or_name", 1, "Expected %s to be player or name", function(args)
	return is_valid_name(args[1]) or mineunit_type(args[1]) == "Player"
end)

local mineunit_types = {
	"Form",
	"ItemStack",
	"InvRef",
	"MetaDataRef",
	"NodeMetaRef",
	"Player"
}
for _, typename in ipairs(mineunit_types) do
	local assertname = "is_" .. typename
	local function checktype(state, args)
		setmsg(state, args[2])
		return mineunit_type(args[1]) == typename
	end
	say:set("assertion."..assertname..".negative", "Expected %s to be "..typename)
	assert:register("assertion", typename, checktype, "assertion."..assertname..".negative")
end

-- Inventory assertions

local function resolve_args_inv_list_slot_stack(a, b, c, d)
	local inv
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
		return thing.x..","..thing.y..","..thing.z
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
			msg = "Expected %s to have %s but found %s"
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
	in_array = in_array,
	round = round,
	is_coordinate = is_coordinate,
	is_valid_name = is_valid_name,
	format_coordinate = format_coordinate,
	has_item = has_item,
	type = mineunit_type,
	luatype = lua_type,
}
