local function DEPRECATED(msg)
	-- TODO: Add configurable behavior to fail or warn when deprectaed things are used
	-- Now it has to be fail. Warnings are for pussies, hard fail for serious Sam.
	error(msg or "Attempted to use deprecated method")
end

function mineunit_export_object(obj, def)
	if _G[def.name] == nil then
		obj.__index = obj
		setmetatable(obj, { __call = def.constructor })
		_G[def.name] = obj
	else
		error("Error: mineunit_export_object object name is already reserved:" .. (def.name or "?"))
	end
end

local function noop(...) end
local function dummy_coords(...) return { x = 123, y = 123, z = 123 } end

_G.world = { nodes = {} }
local world = _G.world
_G.world.set_node = function(pos, node)
	local hash = minetest.hash_node_position(pos)
	world.nodes[hash] = node
	local nodedef = minetest.registered_nodes[node.name]
	-- Execute on_construct callbacks
	if nodedef and type(nodedef.on_construct) == "function" then
		nodedef.on_construct(pos)
	end
end
_G.world.clear = function() _G.world.nodes = {} end
_G.world.layout = function(layout, offset)
	_G.world.clear()
	_G.world.add_layout(layout, offset)
end
_G.world.add_layout = function(layout, offset)
	for _, node in ipairs(layout) do
		local pos = {
			x = node[1].x,
			y = node[1].y,
			z = node[1].z,
		}
		if offset then
			pos.x = pos.x + offset.x
			pos.y = pos.y + offset.y
			pos.z = pos.z + offset.z
		end
		_G.world.set_node(pos, {name=node[2], param2=0})
	end
end

_G.core = {}
_G.minetest = _G.core

mineunit("settings")

_G.core.settings = _G.Settings(fixture_path("minetest.cfg"))

_G.core.register_on_joinplayer = noop
_G.core.register_on_leaveplayer = noop

mineunit("game/item")
mineunit("game/misc")
mineunit("common/misc_helpers")
mineunit("common/vector")
mineunit("common/serialize")

mineunit("metadata")
mineunit("itemstack")

_G.minetest.registered_nodes = {}
_G.minetest.registered_items = {}

_G.minetest.registered_chatcommands = {}

_G.minetest.register_lbm = noop
_G.minetest.register_abm = noop
_G.minetest.register_chatcommand = noop
_G.minetest.chat_send_player = function(...) print(unpack({...})) end
_G.minetest.register_alias = noop
_G.minetest.register_craftitem = function(name, def)
	minetest.registered_items[name] = def
end
_G.minetest.register_craft = noop
_G.minetest.register_node = function(name, def)
	minetest.registered_nodes[name] = def
end
_G.minetest.register_on_placenode = noop
_G.minetest.register_on_dignode = noop
_G.minetest.register_on_mods_loaded = function(func) mineunit:register_on_mods_loaded(func) end
_G.minetest.item_drop = noop

_G.minetest.get_us_time = function()
	local socket = require 'socket'
	-- FIXME: Returns the time in seconds, relative to the origin of the universe.
	return socket.gettime() * 1000 * 1000
end

_G.minetest.get_node_or_nil = function(pos)
	local hash = minetest.hash_node_position(pos)
	return world.nodes[hash]
end
_G.minetest.get_node = function(pos)
	return minetest.get_node_or_nil(pos) or {name="IGNORE",param2=0}
end

_G.minetest.get_worldpath = function(...) return "./spec/fixtures" end
_G.minetest.get_modpath = function(...) return _G.mineunit:get_modpath(...) end
_G.minetest.get_current_modname = function(...) return _G.mineunit:get_current_modname(...) end

--
-- Minetest default noop table
--
local default = { __index = function(...) return function(...)end end }
_G.default = {}
setmetatable(_G.default, default)
