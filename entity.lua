local ObjectRef = {}

function ObjectRef:get_pos() return self._pos end
function ObjectRef:set_pos(value) self._pos = vector.new(value) end
function ObjectRef:get_velocity() return self._velocity end
function ObjectRef:set_velocity(value) self._velocity = value end
function ObjectRef:get_acceleration() return self._acceleration end
function ObjectRef:set_acceleration(value) self._acceleration = value end
function ObjectRef:get_yaw() return self._yaw end
function ObjectRef:set_yaw(value) self._yaw = value end
function ObjectRef:get_pitch() return self._pitch end
function ObjectRef:set_pitch(value) self._pitch = value end
function ObjectRef:get_roll() return self._roll end
function ObjectRef:set_roll(value) self._roll = value end

function ObjectRef:set_animation(value) end
function ObjectRef:set_properties(value) self._properties = value end

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
