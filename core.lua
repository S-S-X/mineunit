local function noop(...) end
local function dummy_coords(...) return { x = 123, y = 123, z = 123 } end
local noop_object = {
	__call = function(self,...) return self end,
	__index = function(...) return function(...)end end,
}

_G.world = mineunit("world")

_G.core.set_node = world.set_node
_G.core.swap_node = world.swap_node

_G.core.get_worldpath = function(...) return _G.mineunit:get_worldpath(...) end
_G.core.get_modpath = function(...) return _G.mineunit:get_modpath(...) end
_G.core.get_current_modname = function(...) return _G.mineunit:get_current_modname(...) end
_G.core.register_item_raw = noop
_G.core.unregister_item_raw = noop
_G.core.register_alias_raw = noop
_G.minetest = _G.core

mineunit("settings")

_G.core.settings = _G.Settings(fixture_path("minetest.cfg"))

_G.core.register_on_joinplayer = noop
_G.core.register_on_leaveplayer = noop

mineunit("game/constants")
mineunit("game/item")
mineunit("game/misc")
mineunit("game/register")
mineunit("game/privileges")
mineunit("common/misc_helpers")
mineunit("common/vector")
mineunit("common/serialize")
mineunit("common/fs")

mineunit("metadata")
mineunit("itemstack")

local mod_storage
_G.minetest.get_mod_storage = function()
	if not mod_storage then
		mod_storage = MetaDataRef()
	end
	return mod_storage
end

_G.minetest.registered_chatcommands = {}
_G.minetest.register_chatcommand = noop
_G.minetest.chat_send_player = function(...) print(unpack({...})) end
_G.minetest.register_on_player_receive_fields = noop
_G.minetest.register_on_placenode = noop
_G.minetest.register_on_dignode = noop
_G.minetest.register_on_mods_loaded = function(func) mineunit:register_on_mods_loaded(func) end
_G.minetest.item_drop = noop

_G.minetest.get_us_time = function()
	local socket = require 'socket'
	-- FIXME: Returns the time in seconds, relative to the origin of the universe.
	return socket.gettime() * 1000 * 1000
end

_G.minetest.after = noop

_G.minetest.get_node_or_nil = function(pos)
	local hash = minetest.hash_node_position(pos)
	return world.nodes[hash]
end
_G.minetest.get_node = function(pos)
	return minetest.get_node_or_nil(pos) or {name="IGNORE",param2=0}
end
_G.minetest.get_node_timer = {}
setmetatable(_G.minetest.get_node_timer, noop_object)

local max_content_id = 0
local content_ids = {}
_G.minetest.get_content_id = function(name)
	-- check if the node exists
	assert(minetest.registered_nodes[name], "node " .. name .. " is not registered")

	-- create and increment
	if not content_ids[name] then
		content_ids[name] = max_content_id
		max_content_id = max_content_id + 1
	end
	return content_ids[name]
end

--
-- Minetest default noop table
-- FIXME: default should not be here, it should be separate file and not loaded with core
--
_G.default = {
	LIGHT_MAX = 14,
	get_translator = string.format,
}
setmetatable(_G.default, noop_object)
