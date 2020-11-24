-- FIXME: Sorry, not exactly nice in its current state
-- Have extra time and energy? Feel free to clean it a bit

local pl = {
	path = require 'pl.path',
	--dir = require 'pl.dir',
}

local default_config = {
	verbose = 2,
	print = true,
	modname = "mineunit",
	root = ".",
	mineunit_path = debug.getinfo(1).source:match("@?(.*)/"),
	fixture_path = "spec/fixtures",
	source_path = "..",
}

mineunit = {
	_config = {
		modpaths = {},
	}
}

local function mineunit_path(name)
	return pl.path.normpath(string.format("%s/%s", mineunit:config("mineunit_path"), name))
end

mineunit.__index = mineunit
local _mineunits = {}
setmetatable(mineunit, {
	__call = function(self, name)
		if not _mineunits[name] then
			local path = mineunit_path(name .. ".lua")
			mineunit:debug("Loading mineunit module", name, path)
			dofile(path)
		end
		_mineunits[name] = true
	end,
})

if mineunit_config then
	for key in pairs(default_config) do
		if mineunit_config[key] ~= nil then
			mineunit._config[key] = mineunit_config[key]
		end
	end
end

function mineunit:config(key)
	if self._config[key] ~= nil then
		return self._config[key]
	end
	return default_config[key]
end

local luaprint = _G.print
function mineunit:debug(...)   if self:config("verbose") > 3 then luaprint(...) end end
function mineunit:info(...)    if self:config("verbose") > 2 then luaprint(...) end end
function mineunit:warning(...) if self:config("verbose") > 1 then luaprint(...) end end
function mineunit:error(...)   if self:config("verbose") > 0 then luaprint(...) end end
function mineunit:print(...)   if self:config("print")       then luaprint(...) end end
_G.print = function(...) mineunit:print(...) end

function mineunit:set_modpath(name, path)
	mineunit:info("Setting modpath", name, path)
	self._config.modpaths[name] = path
end

function mineunit:get_modpath(name)
	return self._config.modpaths[name] or self:config("fixture_path")
end

function mineunit:get_current_modname()
	return self:config("modname")
end

-- FIXME: Not good in any way, only reason is that this works for me...
function fixture_path(name)
	local path = pl.path.normpath(("%s/%s/%s"):format(mineunit:config("root"), mineunit:config("fixture_path"), name))
	if not pl.path.isfile(path) then
		path = pl.path.normpath(("%s/%s/%s"):format(mineunit:config("mineunit_path"), "/../fixtures/", name))
	end
	mineunit:debug("fixture_path", path)
	return path
end

local _fixtures = {}
function fixture(name)
	local path = fixture_path(name .. ".lua")
	if not _fixtures[name] then
		mineunit:info("Loading fixture", path)
		dofile(path)
	else
		mineunit:debug("Fixture already loaded", path)
	end
	_fixtures[name] = true
end

-- FIXME: Not good in any way, only reason is that this works for me...
function source_path(name)
	local path = pl.path.normpath(("%s/%s/%s"):format(mineunit:config("root"), mineunit:config("source_path"), name))
	if not pl.path.isfile(path) then
		local cwd = debug.getinfo(2).source:match("@?(.*)/"):gsub("/spec/", ""):gsub("/%./", "/")
		path = pl.path.normpath(("%s/%s"):format(cwd, path))
	end
	mineunit:debug("source_path", path)
	return path
end

function sourcefile(name)
	local path = source_path(name .. ".lua")
	mineunit:info("Loading source", path)
	dofile(path)
end

function timeit(count, func, ...)
	local socket = require 'socket'
	local t1 = socket.gettime() * 1000
	for i=0,count do
		func(...)
	end
	local diff = (socket.gettime() * 1000) - t1
	local info = debug.getinfo(func,'S')
	mineunit:info(("\nTimeit: %s:%d took %d ticks"):format(info.short_src, info.linedefined, diff))
	return diff, info
end

function count(t)
	if type(t) == "table" or type(t) == "userdata" then
		local c = 0
		for a,b in pairs(t) do
			c = c + 1
		end
		return c
	end
	mineunit:warning("count(t)", "invalid value", type(t))
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
	mineunit:warning("tabletype(t)", "invalid value", type(t))
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
