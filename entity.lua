mineunit("common/vector")

local ObjectRef = {}

function ObjectRef:set_velocity(value) self._velocity = vector.new(value) end
function ObjectRef:get_acceleration() return self._acceleration end
function ObjectRef:set_acceleration(value) self._acceleration = value end
function ObjectRef:get_yaw() return self._yaw end
function ObjectRef:set_yaw(value) self._yaw = value end
function ObjectRef:get_pitch() return self._pitch end
function ObjectRef:set_pitch(value) self._pitch = value end
function ObjectRef:get_roll() return self._roll end
function ObjectRef:set_roll(value) self._roll = value end



function ObjectRef:get_pos() return table.copy(self._pos) end
function ObjectRef:set_pos(value) self._pos = vector.new(value) end
function ObjectRef:get_velocity() return table.copy(self._velocity) end
function ObjectRef:add_velocity(vel)
	-- * `vel` is a vector, e.g. `{x=0.0, y=2.3, z=1.0}`
	-- * In comparison to using get_velocity, adding the velocity and then using
	--   set_velocity, add_velocity is supposed to avoid synchronization problems.
	--   Additionally, players also do not support set_velocity.
	-- * If a player:
	--     * Does not apply during free_move.
	--     * Note that since the player speed is normalized at each move step,
	--       increasing e.g. Y velocity beyond what would usually be achieved
	--       (see: physics overrides) will cause existing X/Z velocity to be reduced.
	--     * Example: `add_velocity({x=0, y=6.5, z=0})` is equivalent to
	--       pressing the jump key (assuming default settings)
end
function ObjectRef:move_to(pos, continuous) -- continuous=false
	-- * Does an interpolated move for Lua entities for visually smooth transitions.
	-- * If `continuous` is true, the Lua entity will not be moved to the current
	--   position before starting the interpolated move.
	-- * For players this does the same as `set_pos`,`continuous` is ignored.
end
function ObjectRef:punch(puncher, time_from_last_punch, tool_capabilities, direction)
	-- * `puncher` = another `ObjectRef`,
	-- * `time_from_last_punch` = time since last punch action of the puncher
	-- * `direction`: can be `nil`
end
function ObjectRef:right_click(clicker)
	--; `clicker` is another `ObjectRef`
end
function ObjectRef:get_hp()
	--: returns number of health points
end
function ObjectRef:set_hp(hp, reason)
	--: set number of health points
	-- * See reason in register_on_player_hpchange
	-- * Is limited to the range of 0 ... 65535 (2^16 - 1)
	-- * For players: HP are also limited by `hp_max` specified in the player's
	--   object properties
end
function ObjectRef:get_inventory()
	--: returns an `InvRef` for players, otherwise returns `nil`
end
function ObjectRef:get_wield_list()
	--: returns the name of the inventory list the wielded item
	-- is in.
end
function ObjectRef:get_wield_index()
	--: returns the index of the wielded item
end
function ObjectRef:get_wielded_item()
	--: returns an `ItemStack`
end
function ObjectRef:set_wielded_item(item)
	--: replaces the wielded item, returns `true` if
	-- successful.
end
function ObjectRef:set_armor_groups(t)
	-- {group1=rating, group2=rating, ...}
end
function ObjectRef:get_armor_groups()
	--: returns a table with the armor group ratings
end
function ObjectRef:set_animation(frame_range, frame_speed, frame_blend, frame_loop)
	-- * `frame_range`: table {x=num, y=num}, default: `{x=1, y=1}`
	-- * `frame_speed`: number, default: `15.0`
	-- * `frame_blend`: number, default: `0.0`
	-- * `frame_loop`: boolean, default: `true`
end
function ObjectRef:get_animation()
	--: returns `range`, `frame_speed`, `frame_blend` and
	-- `frame_loop`.
end
function ObjectRef:set_animation_frame_speed(frame_speed)
	-- * `frame_speed`: number, default: `15.0`
end
function ObjectRef:set_attach(parent, bone, position, rotation, forced_visible)
	--
	-- * `bone`: string. Default is `""`, the root bone
	-- * `position`: `{x=num, y=num, z=num}`, relative, default `{x=0, y=0, z=0}`
	-- * `rotation`: `{x=num, y=num, z=num}` = Rotation on each axis, in degrees.
	--   Default `{x=0, y=0, z=0}`
	-- * `forced_visible`: Boolean to control whether the attached entity
	--    should appear in first person. Default `false`.
	-- * This command may fail silently (do nothing) when it would result
	--   in circular attachments.
end
function ObjectRef:get_attach()
	--: returns parent, bone, position, rotation, forced_visible,
	-- or nil if it isn't attached.
end
function ObjectRef:get_children()
	--: returns a list of ObjectRefs that are attached to the
	-- object.
end
function ObjectRef:set_detach()
end
function ObjectRef:set_bone_position(bone, position, rotation)
	-- * `bone`: string. Default is `""`, the root bone
	-- * `position`: `{x=num, y=num, z=num}`, relative, `default {x=0, y=0, z=0}`
	-- * `rotation`: `{x=num, y=num, z=num}`, default `{x=0, y=0, z=0}`
end
function ObjectRef:get_bone_position(bone)
	--: returns position and rotation of the bone
end
function ObjectRef:set_properties(value) self._properties = value end
function ObjectRef:get_properties() return table.copy(self._properties) end
function ObjectRef:is_player() return true end -- FIXME! This is not actually player, add and test in Player class
function ObjectRef:get_nametag_attributes()
	if not self._nametag_attributes then self._nametag_attributes = {
		text = self._nametag_text or '',
		color = self._nametag_color or { a = 255, r = 255, g = 255, b = 255 },
		bgcolor = self._nametag_bgcolor or { a = 0, r = 0, g = 0, b = 0 },
	}
	end
	return self._nametag_attributes
end
function ObjectRef:set_nametag_attributes(attributes)
	-- * sets the attributes of the nametag of an object
	-- * `attributes`:
	--   {
	--     text = "My Nametag",
	--     color = ColorSpec,
	--     -- ^ Text color
	--     bgcolor = ColorSpec or false,
	--     -- ^ Sets background color of nametag
	--     -- `false` will cause the background to be set automatically based on user settings
	--     -- Default: false
	--   }
	-- TODO: support ColorSpec and bgcolor of false and sync with self._nametag_*
	if not self._nametag_attributes then self:get_nametag_attributes() end
	for key, value in pairs(new_attributes) do
		if nil ~= self._nametag_attributes[key] then
			if 'text' == key then
				self._nametag_attributes.text = tostring(value)
			else
				for subkey, subvalue in pairs(new_attributes[key]) do
					if nil ~= self._nametag_attributes[key][subkey] then
						self._nametag_attributes[key][subkey] = tonumber(subvalue)
					end
				end -- loop a, r, g, b
			end
		end -- if key exists
	end -- loop new_attributes
end

mineunit.export_object(ObjectRef, {
	name = "ObjectRef",
	constructor = function(self)
		local obj = {
			_pos = {x=0, y=0, z=0},
			_velocity = 0,
			_acceleration = 0,
			_yaw = 0,
			_pitch = 0,
			_roll = 0,
			_properties = {},
		}
		setmetatable(obj, ObjectRef)
		return obj
	end,
})

local LuaEntity = {}

mineunit.export_object(LuaEntity, {
	name = "LuaEntity",
	constructor = function(self, data)
		assert(type(data) == "table")
		local obj = {}
		obj.object = ObjectRef()
		setmetatable(obj, data)
		return obj
	end,
})

local EntitySAO = {}

local last_unique_id = -1
local function unique_id()
	last_unique_id = last_unique_id + 1
	return last_unique_id
end

function EntitySAO:get_luaentity()
	return self._luaentity
end

mineunit.export_object(EntitySAO, {
	name = "EntitySAO",
	constructor = function(self, name, staticdata)
		assert(type(name) == "string")
		assert(core.registered_entities[name])
		local obj = {}
		obj._luaentity = LuaEntity(core.registered_entities[name])
		obj._name = name
		obj._staticdata = staticdata
		setmetatable(obj, EntitySAO)
		return obj
	end,
})

local entities = {}

function mineunit:get_entities()
	return entities
end

function _G.core.add_entity(pos, name, staticdata)
	local entity = EntitySAO(name, staticdata)
	if not entities[name] then
		entities[name] = {}
	end
	table.insert(entities[name], entity)
	return entity
end
