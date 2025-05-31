-- Load basic libraries and Mineunit assertions

local assert = require('luassert.assert')
mineunit.utils = require("mineunit.assert")
local noop = mineunit.utils.noop
local _, engine_version_minor = mineunit.utils.explode_version(mineunit:config("engine_version"), -1)

-- Constants

os.setlocale("C")
INIT = "game"
PLATFORM = "Linux"
DIR_DELIM = "/"

-- Engine API

local core = {}

core.add_item = noop
core.add_particlespawner = noop
core.after = noop
core.check_for_falling = noop
core.item_drop = noop
core.load_area = noop
core.notify_authentication_modified = noop
core.register_alias_raw = noop
core.register_chatcommand = noop
core.register_on_dignode = noop
core.register_on_joinplayer = noop
core.register_on_leaveplayer = noop
core.register_on_placenode = noop
core.register_on_player_receive_fields = noop
core.request_http_api = noop
core.sound_fade = noop
core.sound_play = noop
core.sound_stop = noop
core.unregister_item_raw = noop
core.settings = setmetatable({}, {
	__index = function() return function() end end,
	__newindex = function() end,
})

function core.get_builtin_path()
	local tag = mineunit:config("engine_version")
	return (tag == "mineunit" and mineunit:config("mineunit_path")
		or mineunit:config("core_root") .. DIR_DELIM .. tag) .. DIR_DELIM
end

function core.get_worldpath(...)
	return mineunit:get_worldpath(...)
end

function core.get_modpath(...)
	return mineunit:get_modpath(...)
end

function core.get_current_modname(...)
	return mineunit:get_current_modname(...)
end

function core.register_on_mods_loaded(func)
	mineunit:register_on_mods_loaded(func)
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

function core.gettext(value)
	assert.is_string(value, "core.gettext: expected string, got " .. type(value))
	return value
end

function core.is_singleplayer()
	return mineunit:config("singleplayer")
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

function core.inventorycube(img1, img2, img3)
	img2 = img2 or img1
	img3 = img3 or img1
	return "[inventorycube{" .. img1:gsub("%^", "&") .. "{" .. img2:gsub("%^", "&") .. "{" .. img3:gsub("%^", "&")
end

function core.compare_block_status(pos, status)
	return true
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

core.CONTENT_UNKNOWN = 125
core.CONTENT_AIR = 126
core.CONTENT_IGNORE = 127
local content_name2id = {
	unknown = core.CONTENT_UNKNOWN,
	air = core.CONTENT_AIR,
	ignore = core.CONTENT_IGNORE,
}
local content_id2name = {
	[core.CONTENT_UNKNOWN] = "unknown",
	[core.CONTENT_AIR] = "air",
	[core.CONTENT_IGNORE] = "ignore",
}

function core.get_content_id(name)
	-- Check if name is valid. Special case: unknown is always valid but item instead of node
	assert(core.registered_nodes[name] or name == "unknown", "Node '" .. name .. "' is not registered")
	return content_name2id[name]
end

function core.get_name_from_content_id(cid)
	assert(content_id2name[cid], "Unknown content id " .. tostring(cid))
	return content_id2name[cid]
end

function core.register_item_raw(def)
	-- Create new content id for registered nodes
	if def.type == "node" and not content_name2id[assert(def.name)] then
		content_name2id[def.name] = #content_id2name + 1
		table.insert(content_id2name, def.name)
	end
end

-- Engine version compatibility

-- 5.6.x releases had vector defined in engine
if engine_version_minor == 6 then
	_G.vector = { metatable = {} }
end

-- Since 5.5.x http_add_fetch been protected behind private engine set_http_api_lua
if engine_version_minor > 4 then
	function core.set_http_api_lua(fn)
		rawset(core, "http_add_fetch", fn)
	end
end

-- Since 5.7.x get_content_id uses caching, disable it
if engine_version_minor > 6 then
	local overrides = {}
	local function override(key) overrides[key], core[key] = core[key], nil end
	override("get_content_id")
	override("get_name_from_content_id")

	local CORE = {}

	function CORE:__index(key)
		if overrides[key] then
			return overrides[key]
		end
		return rawget(core, key)
	end

	function CORE:__newindex(key, value)
		if overrides[key] == nil then
			rawset(core, key, value)
		end
	end

	core.__index = CORE
	setmetatable(core, CORE)
end
core.__metatable = "locked at globals.lua"

-- Set engine core and its aliases

_G.core = core
_G.minetest = core