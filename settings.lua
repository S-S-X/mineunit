
local Settings = {}

-- https://github.com/minetest/minetest/blob/master/src/util/string.h
local function is_yes(value)
	if tonumber(value) then
		return tonumber(value) ~= 0
	end
	value = tostring(value):lower()
	return (value == "y" or value == "yes" or value == "true")
end

function Settings:get(key)
	mineunit:debug("Settings:get(...)", key, self._data[key])
	return self._data[key]
end

function Settings:get_bool(key, default)
	local value = self._data[key]
	mineunit:debug("Settings:get_bool(...)", key, value and is_yes(value) or value, default)
	if value == nil then
		return default
	end
	return is_yes(value)
end

function Settings:set(key, value)
	self._data[key] = tostring(value)
end

function Settings:set_bool(key, value)
	self:set(key, value and "true" or "false")
end

function Settings:write(...)
	-- noop / not implemented
	mineunit:info("Settings:write(...) called, no operation")
end

function Settings:remove(key)
	mineunit:debug("Settings:remove(...)", key, self._data[key])
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

local function load_conf_file(fname, target)
	file = io.open(fname, "r")
	if file then
		mineunit:debug("Settings object loading values from:", fname)
		for line in file:lines() do
			for key, value in string.gmatch(line, "([^=%s]+)%s*=%s*(.-)%s*$") do
				mineunit:debug("\t", key, "=", value)
				target[key] = value
			end
		end
		mineunit:info("Settings object created from:", fname)
		return true
	end
end

mineunit.export_object(Settings, {
	name = "Settings",
	constructor = function(self, fname)
		local settings = {}
		settings._data = {}
		-- Not even nearly perfect config parser but should be good enough for now
		if not load_conf_file(fname, settings._data) then
			if not load_conf_file(fixture_path(fname), settings._data) then
				mineunit:info("File not found, creating empty Settings object:", fname)
			end
		end
		setmetatable(settings, Settings)
		settings.__index = settings
		return settings
	end,
})
