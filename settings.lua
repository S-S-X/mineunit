
local Settings = {}

function Settings:get(key)
	return self._data[key]
end

function Settings:get_bool(key, default)
	return
end

function Settings:set(key, value)
	self._data[key] = value
end

function Settings:set_bool(key, value)
	self:set(key, value and "true" or "false")
end

function Settings:write(...)
	-- noop / not implemented
end

function Settings:remove(key)
	self._data[key] = nil
	return true
end

function Settings:get_names()
	local result = {}
	for k,_ in pairs(t) do
		table.insert(result, k)
	end
	return result
end

function Settings:to_table()
	local result = {}
	for k,v in pairs(self._data) do
		result[k] = v
	end
	return result
end

mineunit.export_object(Settings, {
	name = "Settings",
	constructor = function(self, fname)
		local settings = {}
		settings._data = {}
		-- Not even nearly perfect config parser but should be good enough for now
		file = io.open(fname, "r")
		if file then
			for line in file:lines() do
				for key, value in string.gmatch(line, "([^=%s]+)%s*=%s*(.-)$") do
					settings._data[key] = value
				end
			end
		end
		setmetatable(settings, Settings)
		settings.__index = settings
		return settings
	end,
})
