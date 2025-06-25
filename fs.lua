--
-- Common things used everywhere
--
local lua_os = mineunit:builtin("os")
local lua_io = mineunit:builtin("io")
local pl_path = require("pl.path")
local basename = pl_path.basename
local function normpath(path)
	return pl_path.normpath(pl_path.abspath(path))
end
local CWD = normpath("")

do
	local io_open = io.open
	-- luacheck: push globals io
	io.open = function(path, ...)
		local result = {io_open(path, ...)}
		if result[1] == nil then
			mineunit:warningf("(real io) could not open file '%s'.", path)
		end
		return unpack(result)
	end
	-- luacheck: pop
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
	local file = lua_io.open(path, "wb")
	assert(file and lua_io.type(file) == "file", "(real fs) core.safe_file_write: could not open file for writing: "..path)
	file:write(content)
	file:close()
end

end, ["FAKE FILESYSTEM"] = function()
-- Use fake filesystem with engine filesystem API

-- our internal normpath will strip out real fs cwd and only returns relative paths
local CWDP = "^" .. CWD:gsub("([%.%-%+%*%%%(%)%[%]])", "%%%1") .. "/?"
local normal_normpath = normpath
normpath = function(path)
	path = normal_normpath(path):gsub(CWDP, "")
	return #path > 0 and path or "."
end

local fs = require('mineunit.lib.fs')(lua_io)
local File = require('mineunit.lib.file')(fs)

fs:reset()

-- luacheck: push globals os
os = {
-- luacheck: pop
	clock = lua_os.clock,
	date = lua_os.date,
	difftime = lua_os.difftime,
	execute = lua_os.execute,
	exit = lua_os.exit,
	getenv = lua_os.getenv,
	remove = function(filename)
		local file, container, refname = fs:get(normpath(filename))
		-- FIXME: Really bad directory handling, get rid of dot self refs
		if file == nil or refname == "." then
			return nil, "ENOENT"
		elseif type(file) == "table" and next(file, next(file)) then
			return nil, "Directory is not empty"
		end
		container[refname] = nil
		return true
	end,
	rename = function(oldname, newname)
		local file1, fs1, refname1 = fs:get(normpath(oldname))
		local file2, fs2, refname2 = fs:get(normpath(newname))
		if not file1 then
			return nil, "ENOENT"
		elseif file2 ~= nil and file2 ~= false and type(file1) ~= type(file2) then
			return nil, "Is " .. (({table = "directory", string = "file"})[type(file1)])
		end
		fs2[refname2], fs1[refname1] = file1, nil
		return true
	end,
	setlocale = lua_os.setlocale,
	time = lua_os.time,
	tmpname = lua_os.tmpname,
}

-- luacheck: push globals io
io = {
-- luacheck: pop
	close = function(file)
		return file and file:close() or lua_io.close()
	end,
	flush = lua_io.flush,
	input = lua_io.input,
	lines = function(filename)
		if filename then
			filename = normpath(filename)
			local content = fs:get(filename)
			assert.is_string(content, "ENOENT: "..tostring(filename))
			-- TODO: Should this include line feed? What about carriage return?
			return content:gmatch("([^\n]*)\n?")
		end
		return lua_io.lines()
	end,
	open = function(filename, mode)
		assert.is_string(filename)
		filename = normpath(filename)
		local file = File(filename, mode)
		if file then
			mineunit:debugf("(fake io) successful io.open('%s', '%s')", file._path, mode)
			rawset(file, "_mineunit_typename", "userdata")
			return file
		end
		mineunit:warningf("(fake io) could not open file '%s'.", filename)
		return nil, "ENOENT"
	end,
	output = lua_io.output,
	popen = lua_io.popen,
	read = lua_io.read,
	stderr = lua_io.stderr,
	stdin = lua_io.stdin,
	stdout = lua_io.stdout,
	tmpfile = lua_io.tmpfile,
	type = function(file)
		-- FIXME: Return nil for non file arguments (also nil) and lua_io.type() for no arguments
		return file and rawget(file, "_type") or lua_io.type(nil)
	end,
	write = lua_io.write,
}

function core.mkdir(path)
	path = normpath(path)
	if fs:is_dir(path) then
		return true
	elseif not fs:get(path) then
		fs:mkdir(path)
		return true
	end
	mineunit:warningf("(fake fs) core.mkdir: could not create directory: %s", path)
	return false
end

function core.get_dir_list(path, list_dirs)
	local results = {}
	local fsobj = fs:get_dir(normpath(path))
	if not fsobj then
		return results
	elseif list_dirs == nil then
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
	assert.is_false(fs:is_dir(path))
	fs:set(path, content)
	return true
end

function mineunit:fs_reset()
	fs:reset()
end

local function fs_copy(src, dst)
	mineunit:infof("Adding '%s' into fake fs as '%s'.", src, dst)
	local srcfile = assert(mineunit:builtin("io").open(src, "rb"), "File not found '"..src.."'")
	local dstfile = io.open(dst, "wb")
	dstfile:write(srcfile:read("*a") or "")
	srcfile:close()
	dstfile:close()
end

local function recursive_copy(src, dst)
	mineunit:infof("Adding '%s' recursively into fake fs as '%s'.", src, dst)
	local substart = #src + 2
	if #dst > 0 then
		core.mkdir(dst)
	end
	for srcpath, is_dir in require("pl.dir").dirtree(src) do
		local dstpath = pl_path.join(dst, srcpath:sub(substart))
		if is_dir then
			core.mkdir(dstpath)
		else
			fs_copy(srcpath, dstpath)
		end
	end
end

function mineunit:fs_copy(src, dst)
	dst = dst or src
	if type(src) == "table" then
		for _, path in ipairs(src) do
			mineunit:fs_copy(path, dst)
		end
	else
		-- Check for relative src path
		--if src:sub(1) ~= DIR_DELIM then
		--	src = mineunit:get_worldpath() .. DIR_DELIM .. src
		--end
		-- Check for relative dst path
		if dst:sub(-1) == DIR_DELIM then
			dst = dst .. basename(src)
		end
		-- Copy files
		if pl_path.isdir(src) then
			recursive_copy(src, dst)
		else
			fs_copy(src, dst)
		end
	end
end

function mineunit:fs_getfile(path)
	-- Get data, ignore other details returned by fs:get
	local data = fs:get(path)
	return data
end

function mineunit:fs_raw()
	return fs
end

end})[mineunit:config("use_real_fs") == true and "REAL FILESYSTEM" or "FAKE FILESYSTEM"]