--
-- Common things used everywhere
--
local pl_path = require("pl.path")
local basename = pl_path.basename
local function normpath(path)
	return pl_path.normpath(pl_path.abspath(path))
end

--
-- Choose from alternatives: real_fs or fake_fs
--
return ({["REAL FILESYSTEM"] = function()
-- Use real host filesystem with engine filesystem API

local pl_dir = require("pl.dir")

function core.mkdir(path)
	path = normpath(path)
	if pl_dir.makepath(path) == true then
		return true
	end
	mineunit:warningf("(real fs) core.mkdir: could not create directory: %s", path)
	return false
end

function core.get_dir_list(path, list_dirs)
	path = normpath(path)
	local results = {}
	if list_dirs == nil then
		for name in pl_path.dir(path) do
			if name ~= "." and name ~= ".." then
				table.insert(results, name)
			end
		end
	elseif list_dirs == true then
		for _,name in ipairs(pl_dir.getdirectories(path)) do
			table.insert(results, basename(name))
		end
	elseif list_dirs == false then
		for _,name in ipairs(pl_dir.getfiles(path)) do
			table.insert(results, basename(name))
		end
	else
		error("(real fs) Invalid list_dirs argument for core.get_dir_list(path, list_dirs)")
	end
	return results
end

function core.safe_file_write(path, content)
	assert.is_string(content)
	path = normpath(path)
	local file = io.open(path, "wb")
	assert(file and io.type(file) == "file", "(real fs) core.safe_file_write: could not open file for writing: "..path)
	file:write(content)
	file:close()
end

end, ["FAKE FILESYSTEM"] = function()
-- Use fake filesystem with engine filesystem API

local fs = {}
fs["."] = fs

local normal_normpath = normpath
local function normpath(path)
	-- TODO: Empty path? Only parent ..?
	return path == "." and "." or normal_normpath(path)
end

function core.mkdir(path)
	path = normpath(path)
	if fs[path] == nil and ({".",".."})[basename(path)] == nil then
		fs[path] = {}
		return true
	end
	mineunit:warningf("(fake fs) core.mkdir: could not create directory: %s", path)
	return false
end

function core.get_dir_list(path, list_dirs)
	local results = {}
	local fsobj = fs[normpath(path)]
	if list_dirs == nil then
		for name, content in pairs(fsobj) do
			name = basename(name)
			if name ~= "." then
				table.insert(results, name)
			end
		end
	elseif list_dirs == true then
		for name, content in pairs(fsobj) do
			if type(content) == "table" then
				name = basename(name)
				if name ~= "." then
					table.insert(results, name)
				end
			end
		end
	elseif list_dirs == false then
		for name, content in pairs(fsobj) do
			if type(content) == "string" then
				table.insert(results, basename(name))
			end
		end
	else
		error("(fake fs) Invalid list_dirs argument for core.get_dir_list(path, list_dirs)")
	end
	return results
end

function core.safe_file_write(path, content)
	path = normpath(path)
	assert.is_string(content)
	assert.not_table(fs[path])
	fs[path] = content
end

end})[mineunit:config("use_real_fs") == true and "REAL FILESYSTEM" or "FAKE FILESYSTEM"]
