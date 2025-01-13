-- Globals defined by Minetest
--
-- For more information see following source files:
-- https://github.com/minetest/minetest/blob/master/src/script/cpp_api/s_base.cpp
-- https://github.com/minetest/minetest/blob/master/src/porting.h

-- Libraries

local assert = require('luassert.assert')

-- Constants

os.setlocale("C")
INIT = "client"
PLATFORM = "Linux"
DIR_DELIM = "/"

-- Engine API

local core = {}
_G.core = core

function core.get_builtin_path()
	local tag = mineunit:config("engine_version")
	return tag ~= "mineunit" and mineunit:config("core_root") .. "/" .. tag or mineunit:config("mineunit_path")
end

function core.global_exists(name)
	return rawget(_G, name) ~= nil
end

function core.log(level, ...)
	if level == "error" then
		mineunit:error(...)
	elseif level == "warning" then
		mineunit:warning(...)
	elseif level == "debug" then
		mineunit:debug(...)
	else
		mineunit:info(...)
	end
end

-- http.lua implements actual usable HTTP API
function core.request_http_api(...) end

function core.gettext(value)
	assert.is_string(value, "core.gettext: expected string, got " .. type(value))
	return value
end

local core_timeofday = 0.5
function core.get_timeofday()
	return core_timeofday
end

function mineunit:set_timeofday(d)
	assert.is_number(d)
	assert(core_timeofday >= 0 and core_timeofday <= 1, "mineunit:set_timeofday(d) requires number from 0 to 1")
	core_timeofday = d
end

function core.get_node_light(pos, timeofday)
	timeofday = timeofday or core.get_timeofday()
	return mineunit.utils.round(math.sin(timeofday * 3.14) * 15)
end

local json = require('mineunit.lib.json')

function core.write_json(...)
	local args = {...}
	local success, result = pcall(function() return json.encode(unpack(args)) end)
	return success and result or nil
end

function core.parse_json(...)
	local args = {...}
	local success, result = pcall(function() return json.decode(unpack(args)) end)
	return success and result or nil
end

local origin
function core.get_last_run_mod() return origin end
function core.set_last_run_mod(v) origin = v end
