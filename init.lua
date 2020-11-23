-- FIXME: Sorry, not exactly nice in its current state
-- Have extra time and energy? Feel free to clean it a bit

local default_config = {
	modname = "mineunit",
	root = ".",
	mineunit_path = debug.getinfo(1).source:match("@?(.*)/"),
	fixture_path = "spec/fixtures",
	source_path = "..",
}

for k,v in pairs(default_config) do
	print("DEFAULT CONFIG", k,v)
end

mineunit = {
	_config = {}
}

local function mineunit_path(name)
	return string.format("%s/%s", mineunit:config("mineunit_path"), name)
end

mineunit.__index = mineunit
local _mineunits = {}
setmetatable(mineunit, {
	__call = function(self, name)
		print("CALL", self, name)
		if not _mineunits[name] then
			dofile(mineunit_path(name) .. ".lua")
		end
		_mineunits[name] = true
	end,
})

function mineunit:config(key)
	print("CONFIG", self, key)
	if self._config[key] ~= nil then
		return self._config[key]
	end
	return default_config[key]
end

if mineunit_config then
	local config_keys = {"modname", "root"}
	for key in ipairs(config_keys) do
		if mineunit_config[key] ~= nil then
			mineunit._config[key] = mineunit_config[key]
		end
	end
end

local pl = {
	path = require 'pl.path',
	dir = require 'pl.dir',
}

function fixture_path(name)
	local path = pl.path.normpath(("%s/%s/%s"):format(mineunit:config("root"), mineunit:config("fixture_path"), name))
	if pl.path.isfile(path) then
		return path
	end
	return pl.path.normpath(("%s/%s/%s"):format(mineunit:config("mineunit_path"), "/../fixtures/", name))
end

local _fixtures = {}
function fixture(name)
	if not _fixtures[name] then
		print("LOADING", fixture_path(name .. ".lua"))
		dofile(fixture_path(name .. ".lua"))
	end
	_fixtures[name] = true
end

function source_path(name)
	return string.format("%s/%s/%s", mineunit:config("root"), mineunit:config("source_path"), name)
end

function sourcefile(name)
	local path = source_path(name) .. ".lua"
	if pl.path.isfile(path) then
		dofile(path)
	end
	local cwd = debug.getinfo(2).source:match("@?(.*)/"):gsub("/spec/?$", ""):gsub("/%./", "/")
	dofile(string.format("%s/%s", cwd, path))
end

function timeit(count, func, ...)
	local socket = require 'socket'
	local t1 = socket.gettime() * 1000
	for i=0,count do
		func(...)
	end
	local diff = (socket.gettime() * 1000) - t1
	local info = debug.getinfo(func,'S')
	print(string.format("\nTimeit: %s:%d took %d ticks", info.short_src, info.linedefined, diff))
end

function count(t)
	if type(t) == "table" or type(t) == "userdata" then
		local c = 0
		for a,b in pairs(t) do
			c = c + 1
		end
		return c
	end
end

local function sequential(t)
	local p = 1
	for i,_ in pairs(t) do
		if i ~= p then return false end
		p = p +1
	end
	return true
end

local function tabletype(t)
	if type(t) == "table" or type(t) == "userdata" then
		if count(t) == #t and sequential(t) then
			return "array"
		else
			return "hash"
		end
	end
end

-- Busted test framework extensions

local assert = require('luassert.assert')
local say = require("say")

local function is_array(_,args) return tabletype(args[1]) == "array" end
say:set("assertion.is_indexed.negative", "Expected %s to be indexed array")
assert:register("assertion", "is_indexed", is_array, "assertion.is_indexed.negative")

local function is_hash(_,args) return tabletype(args[1]) == "hash" end
say:set("assertion.is_hashed.negative", "Expected %s to be hash table")
assert:register("assertion", "is_hashed", is_hash, "assertion.is_hashed.negative")
