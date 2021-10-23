
local players = {}

function mineunit:get_players()
	return players
end

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
	assert.player_or_name(player_or_name, "core.check_player_privs: player_or_name: expected string or Player")
	local player
	if type(player_or_name) == "string" then
		player = core.get_player_by_name(player_or_name)
	else
		player = player_or_name
	end
	assert.is_Player(player, "core.check_player_privs: player does not exist or is not online")
	local missing_privs = {}
	local arg={...}
	for _,priv in ipairs(type(arg[1]) == "table" and arg[1] or arg) do
		if not player._privs[priv] then
			table.insert(missing_privs, priv)
		end
	end
	return #missing_privs == 0, missing_privs
end

function _G.core.get_player_by_name(name)
	return players[name] and players[name]._online and players[name] or nil
end

function _G.core.get_player_ip(...)
	return "127.1.2.7"
end

function _G.core.get_connected_players()
	local result = {}
	for _,player in pairs(players) do
		if player._online then
			table.insert(result, player)
		end
	end
	return result
end

--
-- Mineunit player fixture API
--

mineunit("metadata")

local Player = {}

local function get_pointed_thing(pt)
	return pt.x and { type = "node", above = {x=pt.x,y=pt.y+1,z=pt.z}, under = {x=pt.x,y=pt.y,z=pt.z}, } or pt
end

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
function Player:send_chat_message(message)
	return mineunit:execute_on_chat_message(self:get_player_name(), message)
end

-- TODO: do_metadata_inventory_put does not follow exact engine behavior but should be fine for testing simple inv moves
function Player:do_metadata_inventory_put(pos, listname, index, stack)
	-- Test if items can be moved
	local def = core.registered_nodes[core.get_node(pos).name]
	stack = ItemStack(stack)
	local can_put_count = stack:get_count()
	if def.allow_metadata_inventory_put then
		can_put_count = def.allow_metadata_inventory_put(pos, listname, index, stack, self)
	end
	-- Move items
	if can_put_count > 0 then
		local playerinv = self:get_inventory()
		local inv = core.get_meta(pos):get_inventory()
		local oldstack = inv:get_stack(listname, index)
		if not oldstack:is_empty() and playerinv:room_for_item("main", oldstack) then
			-- Old stack to player inventory if there's enough space
			playerinv:add_item("main", oldstack)
		end
		-- Place stack into inventory
		inv:set_stack(listname, index, stack:take_item(can_put_count))
		-- Return leftovers to player inventory
		if not stack:is_empty() and playerinv:room_for_item("main", stack) then
			-- Leftovers to player inventory if there's enough space
			playerinv:add_item("main", stack)
		end
		-- Callbacks
		if def.on_metadata_inventory_put then
			def.on_metadata_inventory_put(pos, listname, index, stack, self)
		end
	end
end

function Player:do_metadata_inventory_take(pos, listname, index)
	-- Test if items can be moved
	local def = core.registered_nodes[core.get_node(pos).name]
	local inv = core.get_meta(pos):get_inventory()
	local stack = inv:get_stack(listname, index)
	local can_take_count = stack:get_count()
	if def.allow_metadata_inventory_take then
		can_take_count = math.min(def.allow_metadata_inventory_take(pos, listname, index, stack, self), can_take_count)
	end
	-- Move items
	if can_take_count > 0 then
		local playerinv = self:get_inventory()
		if playerinv:room_for_item("main", stack) then
			-- Stack to player inventory if there's enough space
			playerinv:add_item("main", stack)
		end
		-- Remove stack from inventory
		inv:set_stack(listname, index, ItemStack())
		-- Callbacks
		if def.on_metadata_inventory_put then
			def.on_metadata_inventory_take(pos, listname, index, stack, self)
		end
	end
end

function Player:do_set_wieldslot(inv_slot) self._wield_index = inv_slot end

function Player:do_use(pointed_thing)
	error("NOT IMPLEMENTED")
end

function Player:do_place(pointed_thing_or_pos)
	local item, pointed_thing, returnstack = self:get_wielded_item(), get_pointed_thing(pointed_thing_or_pos)
	local craftitem = minetest.registered_craftitems[item:get_name()]
	if craftitem and craftitem.on_place then
		returnstack = craftitem.on_place(item, self, pointed_thing)
	else
		returnstack = minetest.item_place(item, self, pointed_thing, nil)
	end
	if returnstack then
		self._inv:set_stack("main", self._wield_index, returnstack)
	end
end

--
-- Minetest player API methods
--

function Player:get_player_control() return table.copy(self._controls) end
function Player:get_player_control_bits() error("NOT IMPLEMENTED") end
function Player:get_player_name() return self._name end
function Player:is_player() return self._is_player end
function Player:get_wielded_item() return self._inv:get_stack("main", self._wield_index) end
function Player:get_meta() return self._meta end
function Player:get_inventory() return self._inv end

function Player:set_pos(pos) self._pos = table.copy(pos) end
function Player:get_pos() return table.copy(self._pos) end

function Player:get_player_velocity() DEPRECATED() end
function Player:add_player_velocity(vel) DEPRECATED() end

function Player:get_look_dir() return self._look_dir or 0 end
function Player:get_look_vertical() return self._look_vertical or 0 end
function Player:get_look_horizontal() return self._look_horizontal or 0 end
function Player:set_look_vertical(radians) self._look_vertical = radians end
function Player:set_look_horizontal(radians) self._look_horizontal = radians end

function Player:get_look_pitch() DEPRECATED() end
function Player:get_look_yaw() DEPRECATED() end
function Player:set_look_pitch(radians) DEPRECATED() end
function Player:set_look_yaw(radians) DEPRECATED() end

function Player:get_breath() error("NOT IMPLEMENTED") end
function Player:set_breath(value) error("NOT IMPLEMENTED") end
function Player:set_fov(fov, is_multiplier, transition_time) error("NOT IMPLEMENTED") end
function Player:get_fov() error("NOT IMPLEMENTED") end

function Player:set_attribute(attribute, value) DEPRECATED() end
function Player:get_attribute(attribute) DEPRECATED() end

function Player:set_inventory_formspec(formspec) end
function Player:get_inventory_formspec() return "" end
function Player:set_formspec_prepend(formspec) end
function Player:get_formspec_prepend(formspec) return "" end

mineunit.export_object(Player, {
	name = "Player",
	constructor = function(self, name, privs)
		local obj = {
			_name = name or "SX",
			-- Players are always online if server module is not loaded
			_online = not (mineunit.execute_on_joinplayer and true or false),
			_is_player = true,
			_privs = privs or { server = 1, test_priv=1 },
			_controls = {},
			_wield_index = 1,
			_meta = MetaDataRef(),
			_inv = InvRef(),
			_pos = {x=0,y=0,z=0},
		}
		obj._inv:set_size("main", 32)
		players[obj._name] = obj
		setmetatable(obj, Player)
		return obj
	end,
})
