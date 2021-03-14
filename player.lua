
local players = {}

function _G.core.show_formspec(...) mineunit:info("core.show_formspec", ...) end

function _G.core.get_player_privs(name)
	assert.is_string(name, "core.get_player_privs: name: expected string, got "..type(name))
	assert.is_Player(players[name], "core.get_player_privs: player not found: "..name)
	local results = {}
	for k, v in pairs(players[name]._privs) do
		results[k] = v and true
	end
	return results
end

function _G.core.set_player_privs(name, privs)
	assert.is_string(name, "core.set_player_privs: name: expected string, got "..type(name))
	assert.is_table(privs, "core.set_player_privs: privs: expected table, got "..type(privs))
	local new_privs = {}
	for k, v in pairs(privs) do
		new_privs[k] = v and true
	end
	players[name]._privs = new_privs
end

function _G.core.check_player_privs(player_or_name, ...)
	local player_privs
	if type(player_or_name) == "table" or mineunit.utils.type(player_or_name) == "Player" then
		-- FIXME: This should use players[player_or_name:get_player_name()] instead of direct _privs
		player_privs = player_or_name._privs
	else
		assert.is_string(name, "core.check_player_privs: player_or_name: expected string or Player")
		player_privs = players[player_or_name]._privs
	end
	local missing_privs = {}
	local has_priv = false
	local arg={...}
	for _,priv in ipairs(arg) do
		if player_privs[priv] then
			has_priv = true
		else
			table.insert(missing_privs, priv)
		end
	end
	return has_priv, missing_privs
end

function _G.core.get_player_by_name(name)
	return players[name]
end

function _G.core.get_player_ip(...)
	return "127.1.2.7"
end

--
-- Mineunit player fixture API
--

mineunit("metadata")

local Player = {}
--
-- Mineunit player API methods
--
function Player:_set_player_control_state(control, value)
	self._controls[control] = value and value
end
function Player:_reset_player_controls()
	self._controls = {}
end
function Player:_set_is_player(value)
	self._is_player = not not value
end
function Player:_chat(message, channel)
	mineunit:execute_modchannel_message(channel, self:get_player_name(), message)
end

--
-- Minetest player API methods
--

function Player:get_player_control() return table.copy(self._controls) end
function Player:get_player_name() return self._name end
function Player:is_player() return self._is_player end
function Player:get_wielded_item() return self._wield_item end
function Player:get_meta() return self._meta end
function Player:get_inventory() return self._inv end

mineunit.export_object(Player, {
	name = "Player",
	constructor = function(self, name, privs)
		local obj = {
			_name = name or "SX",
			_is_player = true,
			_privs = privs or { server = 1, test_priv=1 },
			_controls = {},
			_wield_item = ItemStack(),
			_meta = MetaDataRef(),
			_inv = InvRef(),
		}
		players[obj._name] = obj
		setmetatable(obj, Player)
		return obj
	end,
})
