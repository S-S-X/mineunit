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

-- Exported while playing default minetest game
local default_player_properties = {
	selectionbox = { -0.3, 0, -0.3, 0.3, 1.7, 0.3 },
	nametag = "",
	nametag_bgcolor = false,
	infotext = "",
	static_save = true,
	backface_culling = false,
	makes_footstep_sound = true,
	is_visible = true,
	textures = { "character.png" },
	physical = false,
	stepheight = 0.60000002384186,
	collisionbox = { -0.3, 0, -0.3, 0.3, 1.7, 0.3 },
	initial_sprite_basepos = { y = 0, x = 0 },
	use_texture_alpha = false,
	show_on_minimap = true,
	automatic_face_movement_dir = false,
	spritediv = { y = 1, x = 1 },
	breath_max = 10,
	nametag_color = { a = 255, b = 255, g = 255, r = 255 },
	visual_size = { y = 1, x = 1, z = 1 },
	mesh = "character.b3d",
	visual = "mesh",
	collide_with_objects = true,
	damage_texture_modifier = "^[brighten",
	shaded = true,
	pointable = true,
	zoom_fov = 0,
	eye_height = 1.4700000286102,
	colors = {{ a = 255, b = 255, g = 255, r = 255 }},
	automatic_rotate = 0,
	hp_max = 20,
	wield_item = "", -- TODO: This should probably be actual item in Player:_wield_index inventory slot
	automatic_face_movement_max_rotation_per_sec = -1,
	glow = 0
}

--
-- Mineunit player API methods
--

local function get_pointed_thing(player, pointed_thing_or_pos)
	local pointed_thing
	if pointed_thing_or_pos.x then
		-- Coordinates supplied, find out real pointed_thing assuming next thing from position is node
		local pos = pointed_thing_or_pos
		local playerpos = player:get_pos()
		playerpos.y = playerpos.y + player:get_properties().eye_height
		-- Do not actually care about facing, allow placing to impossible positions if asked to
		local pos_dir = vector.direction(playerpos, pointed_thing_or_pos)
		pointed_thing = {
			type = "node",
			above = vector.round(pos),
			under = vector.round(vector.add(pos, pos_dir))
		}
	else
		pointed_thing = table.copy(pointed_thing_or_pos)
	end
	return pointed_thing
end

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

-- TODO: count -1 might be used wrong here, verify against actual engine behavior
local function swap_stack(toinv, tolist, toindex, frominv, fromlist, fromindex, count)
	-- Get source stack
	local stack = frominv:get_stack(fromlist, fromindex)

	-- Move old stack from target to source first, clear source if target is empty
	local oldstack = toinv:get_stack(tolist, toindex)
	if count ~= -1 then
		if oldstack:is_empty() then
			frominv:set_stack(fromlist, fromindex, nil)
		elseif frominv:room_for_item(fromlist, oldstack) then
			frominv:add_item(fromlist, oldstack)
		end
	end

	-- Place source stack into target inventory
	local placedstack = count ~= -1 and stack:take_item(count) or ItemStack(stack)
	toinv:set_stack(tolist, toindex, placedstack)

	-- Return leftovers to source inventory
	if count ~= -1 and not stack:is_empty() and frominv:room_for_item(fromlist, stack) then
		frominv:add_item(fromlist, stack)
	end
	return placedstack
end

-- TODO: do_metadata_inventory_put does not follow exact engine behavior but should be fine for testing simple inv moves
-- TODO: It might be simpler and more useful for tests to just discard leftovers and always clear source inventory
function Player:do_metadata_inventory_put(pos, tolist, toindex, index_or_stack)
	-- Get node name and definition at target position
	local name = core.get_node(pos).name
	local def = core.registered_nodes[name]
	assert(def, "Player:do_metadata_inventory_put unknown node: "..tostring(name))

	-- Select source inventory based on index_or_stack contents and type
	local frominv, fromindex
	if index_or_stack == nil or type(index_or_stack) == "number" then
		frominv = self:get_inventory()
		fromindex = index_or_stack or self._wield_index
	else
		frominv = InvRef()
		frominv:set_size("main", 1)
		frominv:set_stack("main", 1, index_or_stack)
		fromindex = 1
	end

	-- Test if target accepts stack and stack can be moved
	local stack = frominv:get_stack("main", fromindex)
	local can_put_count
	if def.allow_metadata_inventory_put then
		can_put_count = def.allow_metadata_inventory_put(pos, tolist, toindex, stack, self)
		assert(type(can_put_count) == "number", "allow_metadata_inventory_put returns invalid value for "..name)
	else
		can_put_count = stack:get_count()
	end

	-- Move items (can_put_count == -1 should pass but leave source unmodified)
	if can_put_count > 0 or can_put_count == -1 then
		local toinv = core.get_meta(pos):get_inventory()
		local placedstack = swap_stack(toinv, tolist, toindex, frominv, "main", fromindex, can_put_count)

		-- Execute callbacks
		if def.on_metadata_inventory_put and not placedstack:is_empty() then
			def.on_metadata_inventory_put(pos, tolist, toindex, placedstack, self)
		end
	end
	return can_put_count
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

function Player:do_use(pointed_thing_or_pos)
	local pointed_thing = get_pointed_thing(self, pointed_thing_or_pos)
	local item = self:get_wielded_item()
	local itemdef = core.registered_items[item:get_name()]
	if itemdef and itemdef.on_use then
		local returnstack = itemdef.on_use(item, self, pointed_thing)
		if returnstack then
			assert.is_ItemStack(returnstack)
			self._inv:set_stack("main", self._wield_index, ItemStack(returnstack))
		end
	end
end

function Player:do_place(pointed_thing_or_pos)
	local pointed_thing = get_pointed_thing(self, pointed_thing_or_pos)
	local item = self:get_wielded_item()
	local itemdef = core.registered_items[item:get_name()]
	if itemdef then
		local returnstack
		if itemdef.on_place and pointed_thing.type == "node" then
			returnstack = itemdef.on_place(item, self, pointed_thing)
		elseif itemdef.on_secondary_use and pointed_thing.type ~= "node" then
			returnstack = itemdef.on_secondary_use(item, self, pointed_thing)
		end
		if returnstack then
			assert.is_ItemStack(returnstack)
			self._inv:set_stack("main", self._wield_index, ItemStack(returnstack))
		end
	end
end

function Player:do_place_from_above(pos)
	-- Wrapper to move player above given position, look downwards and place to exact position
	self:set_pos(vector.add(pos, {x=0,y=1,z=0}))
	self:do_set_look_xyz("Y-")
	self:do_place({ type = "node", above = {x=pos.x, y=pos.y, z=pos.z}, under = {x=pos.x, y=pos.y-1, z=pos.z} })
	-- TODO / TBD: Restore original position and camera orientation?
end

function Player:do_set_pos_fp(pos)
	-- Set camera/crosshair position for first person view, eyes will be at pos instead of entity
	self:set_pos({x=pos.x, y=pos.y-self:get_properties().eye_height, z=pos.z})
end

function Player:do_set_look_xyz(xyz)
	assert(type(xyz) == "string", "do_set_look_xyz requires string X+, X-, Y+, Y-, Z+ or Z-")
	local r90 = math.pi / 2
	local look = {
		["X+"] = {0, math.pi + r90},
		["X-"] = {0, r90},
		["Y+"] = {-r90, nil},
		["Y-"] = {r90, nil},
		["Z+"] = {0, 0},
		["Z-"] = {0, math.pi},
	}
	dir = look[xyz:sub(1,2):upper()]
	assert(dir, "do_set_look_xyz requires string X+, X-, Y+, Y-, Z+ or Z-")
	self:set_look_vertical(dir[1])
	if dir[2] then
		self:set_look_horizontal(dir[2])
	end
end

function Player:do_set_look_vertical(radians_or_heading)
	if type(radians_or_heading) == "string" then
		local r90 = math.pi / 2
		local tilt = { U = -r90, F = 0, D = r90 }
		radians_or_heading = tilt[radians_or_heading:sub(1,1):upper()]
		-- It is possible to set view all the way upside down but decided to not include that, seems buggy on client
		assert(radians_or_heading, "Unknown heading, must be radians or one of Up, Forward, Down")
	end
	self:set_look_vertical(radians_or_heading)
end

function Player:do_set_look_horizontal(radians_or_heading)
	if type(radians_or_heading) == "string" then
		local r90 = math.pi / 2
		local compass = { N = 0, E = math.pi + r90, S = math.pi, W = r90 }
		radians_or_heading = compass[radians_or_heading:sub(1,1):upper()]
		assert(radians_or_heading, "Unknown heading, must be radians or one of North, East, South, West")
	end
	self:set_look_horizontal(radians_or_heading)
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

--[[
-- FIXME: Remove or keep these? ObjectRef implements these methods.
function Player:set_pos(pos) self._pos = table.copy(pos) end
function Player:get_pos() return table.copy(self._pos) end
--]]

function Player:get_player_velocity() DEPRECATED() end
function Player:add_player_velocity(vel) DEPRECATED() end

function Player:get_look_dir()
	local pitch, yaw = self:get_look_vertical(), self:get_look_horizontal()
	return { x = math.cos(pitch) * math.sin(yaw), y = math.sin(pitch), z = math.cos(pitch) * math.cos(yaw) }
end

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

function Player:get_eye_offset() return self._eye_offset_first, self._eye_offset_third end

function Player:set_attribute(attribute, value) DEPRECATED() end
function Player:get_attribute(attribute) DEPRECATED() end

function Player:set_inventory_formspec(formspec) end
function Player:get_inventory_formspec() return "" end
function Player:set_formspec_prepend(formspec) end
function Player:get_formspec_prepend(formspec) return "" end

function Player:__index(key)
	local result = rawget(Player, key)
	if not result then
		if type(ObjectRef[key]) == "function" then
			local object = self._object
			return function(...)
				local args = {...}
				table.remove(args, 1)
				return ObjectRef[key](object, unpack(args))
			end
		end
		result = self._object[key]
	end
	return result
end

mineunit("entity")
mineunit.export_object(Player, {
	name = "Player",
	constructor = function(self, name, privs)
		-- TBD: Error or replace player if created again with existing name
		--assert(players[name] == nil, "Player with name already exists: "..tostring(name))
		local object = ObjectRef()
		object:set_pos({x=0,y=0,z=0})
		object:set_properties(table.copy(default_player_properties))
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
			_object = object,
			_look_dir = {x=0,y=-1,z=0}, -- Reflects simplified pointed_thing used to place nodes
			_eye_offset_first = {x=0,y=0,z=0},
			_eye_offset_third = {x=0,y=0,z=0},
		}
		obj._inv:set_size("main", 32)
		players[obj._name] = obj
		setmetatable(obj, Player)
		return obj
	end,
})
