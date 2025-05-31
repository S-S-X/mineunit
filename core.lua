local noop = mineunit.utils.noop
local noop_object = {
	__call = function(self) return self end,
	__index = function() return noop end,
}

local _, engine_version_minor = mineunit.utils.explode_version(mineunit:config("engine_version"), -1)

mineunit("craft")
mineunit("world")

_G.core.set_node = world.set_node
_G.core.add_node = world.set_node
_G.core.swap_node = world.swap_node

_G.minetest = _G.core

mineunit("settings")
_G.core.settings = _G.Settings(fixture_path("minetest.conf"))
mineunit:apply_default_settings(_G.core.settings)

mineunit("fs")
if engine_version_minor > 5 then
	mineunit("./init", { strict = true })
else
	mineunit("game/constants")
	mineunit("common/vector")
	mineunit("game/item")
	mineunit("game/misc")
	mineunit("game/register")
	mineunit("common/misc_helpers")
	mineunit("game/privileges")
	mineunit("game/features")
	mineunit("common/serialize")
end

_G.core.get_translator = function(...) return function(...) mineunit:debug(...) end end

assert(core.registered_nodes["air"])
assert(core.registered_nodes["ignore"])
assert(core.registered_items[""])
assert(core.registered_items["unknown"])

function core.send_join_message(...) mineunit:info("Player joined:", ...) end
function core.send_leave_message(...) mineunit:info("Player left:", ...) end

mineunit("metadata")
mineunit("itemstack")

local mod_storage = {}
_G.core.get_mod_storage = function()
	local modname = core.get_current_modname()
	if not mod_storage[modname] then
		mineunit:debugf("Initializing mod storage for %s", modname)
		mod_storage[modname] = MetaDataRef()
	end
	return mod_storage[modname]
end

-- Detached inventories
local inv_storage = {}
_G.core.get_inventory = function(where)
	assert.is_hashed(where)
	assert.is_string(where.name)
	if where.type == "detached" then
		return inv_storage[where.name]
	elseif where.type == "node" then
		assert.is_coordinate(where.pos)
		local meta = core.get_meta(where.pos)
		return meta and meta:get_inventory() or nil
	elseif where.type == "player" then
		local player = core.get_player_by_name(where.name)
		return player and player:get_inventory() or nil
	end
	error("core.get_inventory(): Invalid inventory type")
end
_G.core.create_detached_inventory = function(name, callbacks, player_name)
	assert.is_string(name)
	mineunit:debugf("Initializing detached inventory '%s'", name)
	if player_name then
		mineunit:warningf("core.create_detached_inventory(...): ignored player name '%s'", player_name)
	end
	inv_storage[name] = InvRef()
	return inv_storage[name]
end
_G.core.remove_detached_inventory = function(name)
	assert.is_string(name)
	if inv_storage[name] then
		inv_storage[name] = nil
		return true
	end
	return false
end

_G.core.registered_chatcommands = core.registered_chatcommands or {}
_G.core.chat_send_player = function(...) print(unpack({...})) end
_G.core.chat_send_all = function(...) print(unpack({...})) end

_G.core.get_objects_inside_radius = function() return {} end
_G.core.objects_inside_radius = function() return noop end -- 5.9.0
_G.core.get_objects_in_area = function() return {} end
_G.core.objects_in_area = function() return noop end -- 5.9.0

_G.core.register_biome = noop
_G.core.clear_registered_biomes = function() error("MINEUNIT UNSUPPORTED CORE METHOD") end
_G.core.register_ore = noop
_G.core.clear_registered_ores = function() error("MINEUNIT UNSUPPORTED CORE METHOD") end
_G.core.register_decoration = noop
_G.core.clear_registered_decorations = function() error("MINEUNIT UNSUPPORTED CORE METHOD") end

do
	local time_step = tonumber(mineunit:config("time_step"))
	assert(time_step, "Invalid configuration value for time_step. Number expected.")
	if time_step < 0 then
		mineunit:info("Running default core.get_us_time using real world wall clock.")
		_G.core.get_us_time = function()
			local socket = require 'socket'
			-- FIXME: Returns the time in seconds, relative to the origin of the universe.
			return socket.gettime() * 1000 * 1000
		end
	else
		mineunit:info("Running custom core.get_us_time with step increment: "..tostring(time_step))
		local time_now = 0
		_G.core.get_us_time = function()
			time_now = time_now + time_step
			return time_now
		end
	end
end

_G.core.find_nodes_with_meta = _G.world.find_nodes_with_meta
_G.core.find_nodes_in_area = _G.world.find_nodes_in_area
_G.core.get_node_or_nil = _G.world.get_node
_G.core.get_node = function(pos) return core.get_node_or_nil(pos) or {name="ignore",param1=0,param2=0} end
_G.core.dig_node = function(pos) return world.on_dig(pos) and true or false end
_G.core.remove_node = _G.world.remove_node

_G.core.get_node_timer = {}
setmetatable(_G.core.get_node_timer, noop_object)

--
-- Minetest default noop table
-- FIXME: default should not be here, it should be separate file and not loaded with core
--
_G.default = {
	LIGHT_MAX = 14,
	get_translator = string.format,
}
setmetatable(_G.default, noop_object)
