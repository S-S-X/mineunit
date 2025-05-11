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

-- FS is flat filesystem where top level contains all the subdirectories and
-- there's no recursion, files however are within their own subdirectories.
-- FS isn't convenient user facing API and wants some kind of wrapper.
local FS = {}
FS.__index = FS
local FS_DATA = {}

function FS:mkdir(path)
	FS_DATA[path] = {}
	FS_DATA[path]["."] = FS_DATA[path]
end

function FS:get(path)
	local ftype = type(FS_DATA[path])
	if ftype == "table" or ftype == "string" then
		return FS_DATA[path], FS_DATA, path
	end
	local name = basename(path)
	local parent = path:sub(1, -2-#name)
	if #parent > 0 and type(FS_DATA[parent]) == "table" then
		return FS_DATA[parent][name], FS_DATA[parent], name
	end
	return FS_DATA[name], FS_DATA, name
end

function FS:set(path, value)
	assert.not_table(FS_DATA[path])
	local name = basename(path)
	local parent = path:sub(1, -2-#name)
	if #parent > 0 then
		FS_DATA[parent] = FS_DATA[parent] or {}
		FS_DATA[parent][name] = value
	else
		FS_DATA[name] = value
	end
	return #value
end

function FS:get_dir(path)
	return self:is_dir(path) and FS_DATA[path] or nil
end

function FS:is_dir(path)
	return type(FS_DATA[path]) == "table"
end

function FS:reset()
	FS_DATA = {}
	FS_DATA["."] = FS_DATA
end

local fs = setmetatable({}, FS)
fs:reset()

local File = {}
File.__index = File

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
		if file1 == nil then
			return nil, "ENOENT"
		elseif file2 ~= nil and type(file1) ~= type(file2) then
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
		local file = {
			_mineunit_typename = "userdata",
			_type = "file",
			_mode = 0, -- 0 = readonly, 1 = replace, 2 = truncate, 3 = noseek
			_read = false,
			_time = core.get_us_time and core.get_us_time() or 0,
			_path = normpath(filename),
			_fpos = 0,
		}
		-- FIXME: Check if file is valid, implement all modes properly
		local m = (mode or " "):gmatch(".")
		if not fs:is_dir(file._path) and setmetatable({
				r = function()
					if m() == "+" or m() == "+" then
						file._mode = 1
					end
					file._read = true
					return fs:get(file._path)
				end,
				a = function()
					local data, parent, path = fs:get(file._path)
					if data == nil then
						parent[path] = ""
					end
					file._mode = 3
					file._fpos = #parent[path]
					return true
				end,
				w = function()
					fs:set(file._path, "")
					file._mode = 2
					return true
				end,__index = function() error("(fake io) io.open unknown mode") end
			},{ __index = function(s,k) return rawget(s,k) or function() end end })[m()]() then
			mineunit:debugf("(fake io) successful io.open('%s', '%s')", file._path, mode)
			setmetatable(file, File)
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

function File:close()
	assert(rawget(self, "_type") == "file", "EBADFD")
	rawset(self, "_type", "closed file")
	mineunit:debugf("(fake io) closed file '%s'", rawget(self, "_path"))
	return true
end

function File:flush()
	assert(rawget(self, "_type") == "file", "EBADFD")
	return true
end

function File:lines()
	assert(rawget(self, "_type") == "file", "EBADFD")
	return io.lines(rawget(self, "_path"))
end

-- "*n": reads a number; this is the only format that returns a number instead of a string.
-- "*a": reads the whole file, starting at the current position. On end of file, it returns the empty string.
-- "*l": reads the next line (skipping the end of line), returning nil on end of file. This is the default format.
-- number: reads a string with up to this number of characters, returning nil on end of file. If number is zero,
--       it reads nothing and returns an empty string, or nil on end of file.
function File:read(what)
	assert(rawget(self, "_type") == "file", "EBADFD")
	local fpos = rawget(self, "_fpos")
	local data = fs:get(rawget(self, "_path"))
	local size = #data
	if not rawget(self, "_read") then
		return nil, "EBADFD"
	elseif type(what) == "number" then
		if fpos < size then
			local s = data:sub(fpos + 1, fpos + what)
			rawset(self, "_fpos", fpos + #s)
			return s
		end
		return nil
	else
		what = what and what:sub(1,2) or "*l"
		if what == "*n" then
			error("NOT IMPLEMENTED")
		elseif what == "*a" then
			rawset(self, "_fpos", size)
			return data:sub(fpos + 1)
		elseif what == "*l" and (size < 1 or fpos >= size) then
			return nil
		elseif what == "*l" then
			local s = data:sub(fpos + 1):match("[^\n]*")
			rawset(self, "_fpos", math.min(size, fpos + #s + 1))
			return s
		end
	end
	error("(fake io) file:read() Invalid argument")
end

-- "set": base is position 0 (beginning of the file).
-- "cur": base is current position (default).
-- "end": base is end of file.
function File:seek(whence, offset)
	if whence == nil then whence = "cur" end
	if offset == nil then offset = 0 end
	assert.is_string(whence)
	assert.is_integer(offset)
	local newpos
	if rawget(self, "_type") ~= "file" then
		return nil, "EBADFD"
	end
	if whence == "cur" then
		newpos = rawget(self, "_fpos") + offset
	elseif whence == "end" then
		newpos = #fs:get(rawget(self, "_path")) + offset
	elseif whence == "set" then
		newpos = offset
	else
		return nil, "Invalid arguments"
	end
	rawset(self, "_fpos", newpos)
	return true
end

function File:setvbuf()
	assert(rawget(self, "_type") == "file", "EBADFD")
	return true
end

function File:write(...)
	assert(rawget(self, "_type") == "file", "EBADFD")
	-- FIXME: Write numbers
	local mode = rawget(self, "_mode")
	local fpos = rawget(self, "_fpos")
	local data = fs:get(rawget(self, "_path"))
	local length = 0
	if mode == 0 then
		return nil, "EBADFD"
	elseif mode == 1 then
		-- Replace, zero pad as needed
		local s = fpos > #data and table.concat({("\0"):rep(fpos - #data),...}) or table.concat({...})
		length = #s
		if length >= #data - fpos then
			if fpos > 0 then
				-- End of data can be ignored
				fs:set(rawget(self, "_path"), data:sub(1,fpos)..s)
			else
				-- Both sides can be ignored, just replace everything
				fs:set(rawget(self, "_path"), s)
			end
		elseif fpos < 1 then
			-- Beginning can be ignored
			fs:set(rawget(self, "_path"), s..data:sub(length + 1))
		else
			-- Both sides are important
			fs:set(rawget(self, "_path"), table.concat({
				data:sub(1,fpos),s,data:sub(fpos + length + 1)
			}))
		end
	elseif mode == 2 and fpos < 1 then
		-- Truncate, FIXME: should we do zero padding?
		length = fs:set(rawget(self, "_path"), table.concat({...}))
		fpos = 0
	elseif mode == 2 then
		-- Truncate at fpos, FIXME: should we do zero padding?
		length = fs:set(rawget(self, "_path"), table.concat({data:sub(1,fpos),...}))
		fpos = 0
	elseif mode == 3 then
		-- Append only, FIXME: should we do zero padding?
		length = fs:set(rawget(self, "_path"), table.concat({data,...}))
	else
		error("(fake io) Invalid file mode, this is probably a bug in Mineunit fs module.")
	end
	rawset(self, "_fpos", fpos + length)
	return true
end

File.__newindex = error

function core.mkdir(path)
	path = normpath(path)
	if fs:is_dir(path) then
		return true
	elseif fs:get(path) == nil then
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
