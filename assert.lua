
local function round(value)
	return (value < 0) and math.ceil(value - 0.5) or math.floor(value + 0.5)
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

local lua_type = type

local function mineunit_type(obj)
	return lua_type(obj) == "table" and lua_type(obj._mineunit_typename) == "string" and obj._mineunit_typename
end

function type(value)
	return mineunit_type(value) and "userdata" or lua_type(value)
end

-- Mineunit luassert extensions

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

-- TODO: Check this one, should it actually check for mineunit_type Player instead of tble or userdata
local function player_or_name(_,args)
	return (type(args[1]) == "string" and args[1] ~= "") or in_array(type(args[1]), {"table", "userdata"})
end
say:set("assertion.player_or_name.negative", "Expected %s to be player or name")
assert:register("assertion", "player_or_name", player_or_name, "assertion.player_or_name.negative")

local mineunit_types = {
	"ItemStack",
	"InvList",
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

-- Replace builtin assert with luassert

_G.assert = assert

-- TODO: Something wrong with this

return {
	sequential = sequential,
	count = count,
	tabletype = tabletype,
	round = round,
	type = mineunit_type
}
