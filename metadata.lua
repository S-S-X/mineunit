
local MetaDataRef = {}
function MetaDataRef._create_instance(value)
	local obj
	if value == nil then
		obj = {}
	elseif type(value) == "table" then
		 obj = table.copy(value)
	else
		error("TYPE NOT IMPLEMENTED: " .. type(value))
	end
	obj._data = obj._data or {}
	setmetatable(obj, MetaDataRef)
	return obj
end
function MetaDataRef:contains(key) return self._data[key] ~= nil end
function MetaDataRef:get(key) return self._data[key] end
function MetaDataRef:set_string(key, value)
	value = value ~= nil and tostring(value)
	self._data[key] = value ~= "" and value
end
function MetaDataRef:get_string(key) return self._data[key] end
function MetaDataRef:set_int(key, value) self:set_string(key, value) end
function MetaDataRef:get_int(key) return math.floor(tonumber(self._data[key]) or 0) end
function MetaDataRef:set_float(key, value) error("NOT IMPLEMENTED") end
function MetaDataRef:get_float(key) error("NOT IMPLEMENTED") end
function MetaDataRef:to_table() error("NOT IMPLEMENTED") end
function MetaDataRef:from_table(t) error("NOT IMPLEMENTED") end
function MetaDataRef:equals(other) error("NOT IMPLEMENTED") end
setmetatable(MetaDataRef, { __call = function(value) return MetaDataRef._create_instance(value) end })
_G.MetaDataRef = MetaDataRef

-- FIXME: Node metadata should be integrated with world layout to handle set_node and its friends
local worldmeta = {}
_G.minetest.get_meta = function(pos)
	local nodeid = minetest.hash_node_position(pos)
	if not worldmeta[nodeid] then
		worldmeta[nodeid] = MetaDataRef()
	end
	return worldmeta[nodeid]
end
