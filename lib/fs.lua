-- FS is flat filesystem where top level contains all the subdirectories and
-- there's no recursion, files however are within their own subdirectories.
-- FS isn't convenient user facing API and wants some kind of wrapper.
-- Files and directories can be in three different states:
--   path not tracked: nil
--   path available: table/string
--   path removed: false

local basename = require("pl.path").basename

local FS = {}
FS.__index = FS

local function parent_id(data, path)
	local name = basename(path)
	local parent = path:sub(1, -2 - #name)
	if #parent > 0 then -- and type(data[parent]) == "table"
		return parent, name
	end
	return nil, name
end

function FS:mkdir(path)
	assert(not self._data[path], "FS:mkdir(path): Path already exists.")
	self._data[path] = {}
	self._data[path]["."] = self._data[path]
end

function FS:rm(path)
	if self._data[path] == nil then
		local parent, name = parent_id(self._data, path)
		if parent and self._data[parent][name] ~= nil then
			self._data[parent][name] = false
		end
	else
		self._data[path] = false
	end
end

function FS:is_tracked(path)
	if self._data[path] == nil then
		local parent, name = parent_id(self._data, path)
		return parent and self._data[parent][name] ~= nil
	end
	return true
end

function FS:get(path)
	if self._data[path] then
		return self._data[path], self._data, path
	end
	local parent, name = parent_id(self._data, path)
	if parent then
		return self._data[parent][name], self._data[parent], name
	end
	return self._data[name], self._data, name
end

function FS:set(path, value)
	assert.not_table(value)
	assert.not_table(self._data[path])
	local parent, name = parent_id(self._data, path)
	if parent then
		self._data[parent][name] = value
	else
		self._data[name] = value
	end
	return #value
end

function FS:get_dir(path)
	return self:is_dir(path) and self._data[path] or nil
end

function FS:is_dir(path)
	return type(self._data[path]) == "table"
end

function FS:reset(path)
	if path then
		local parent, name = parent_id(self._data, path)
		if parent then
			self._data[parent][name] = nil
		else
			self._data[name] = nil
		end
	else
		self._data = {}
		self._data["."] = self._data
	end
end

local fs = setmetatable({
	_data = {}
}, FS)

return fs