-- FS is flat filesystem where top level contains all the subdirectories and
-- there's no recursion, files however are within their own subdirectories.
-- FS isn't convenient user facing API and wants some kind of wrapper.
-- Files and directories can be in three different states:
--   path not tracked: nil
--   path available: table/string
--   path removed: false

local join = require("pl.path").join
local isdir = require("pl.path").isdir
local isfile = require("pl.path").isfile
local basename = require("pl.path").basename

local FS = {}
FS.__index = FS

local function fs_copy(fs, src, dst)
	mineunit:infof("Adding '%s' into fake fs as '%s'.", src, dst)
	local srcfile = assert(fs._io.open(src, "rb"), "File not found '"..src.."'")
	fs:set(dst, srcfile:read("*a") or "")
	srcfile:close()
end

local function recursive_copy(fs, src, dst)
	mineunit:infof("Adding '%s' recursively into fake fs as '%s'.", src, dst)
	local substart = #src + 2
	if #dst > 0 then
		fs:mkdir(dst)
	end
	for srcpath, is_dir in require("pl.dir").dirtree(src) do
		local dstpath = join(dst, srcpath:sub(substart))
		if is_dir then
			fs:mkdir(dstpath)
		else
			fs_copy(fs, srcpath, dstpath)
		end
	end
end

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

function FS:rmdir(path)
	self._data[path] = false
end

function FS:rm(path)
	if self._data[path] == nil then
		local parent, name = parent_id(self._data, path)
		if parent and self._data[parent] and self._data[parent][name] ~= nil then
			self._data[parent][name] = false
		else
			self._data[path] = false
		end
	else
		self._data[path] = false
	end
end

function FS:is_tracked_dir(path)
	return self._data[path] ~= nil
end

function FS:is_tracked(path)
	if self._data[path] == nil then
		local parent, name = parent_id(self._data, path)
		return parent and self._data[parent] and self._data[parent][name] ~= nil
	end
	return true
end

function FS:get(path)
	if not self:is_tracked(path) then
		-- Start tracking file from secondary file system
		if isfile(path) then
			fs_copy(self, path, path)
		else
			self:rm(path)
		end
	end
	-- Get file contents
	if self._data[path] then
		return self._data[path], self._data, path
	end
	local parent, name = parent_id(self._data, path)
	if parent and self._data[parent] then
		return self._data[parent][name], self._data[parent], name
	end
	return self._data[path], self._data, name
end

function FS:set(path, value)
	assert.not_table(value)
	assert.not_table(self._data[path])
	local parent, name = parent_id(self._data, path)
	if parent then
		if self._data[parent] == nil then
			self:mkdir(parent)
		end
		self._data[parent][name] = value
	else
		self._data[name] = value
	end
	return #value
end

function FS:get_dir(path)
	if not self:is_tracked_dir(path) then
		-- Start tracking directory from secondary file system
		if isdir(path) then
			-- FIXME: Should not overwrite already tracked file paths
			recursive_copy(self, path, path)
		else
			self:rmdir(path)
		end
	end
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

return function(io_api)
	return setmetatable({
		_io = io_api,
		_data = {},
	}, FS)
end