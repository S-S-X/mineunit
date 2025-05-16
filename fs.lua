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

do
	local io_open = io.open
	io.open = function(path, ...)
		local result = {io_open(path, ...)}
		if result[1] == nil then
			mineunit:warningf("(real io) could not open file '%s'.", path)
		end
		return unpack(result)
	end
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

local fs = {}
fs["."] = fs

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
		filename = basename(filename)
		if not fs[filename] then
			return nil, "ENOENT"
		end
		fs[filename] = nil
		return true
	end,
	rename = function(oldname, newname)
		oldname, newname = basename(oldname), basename(newname)
		if fs[newname] and type(fs[newname]) ~= type(fs[oldname]) then
			-- TODO: Error messages?
			return nil, "EIO"
		end
		fs[newname], fs[oldname] = fs[oldname], nil
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
			local content = fs[normpath(filename)]
			assert.is_string(content, "ENOENT: "..tostring(filename))
			-- TODO: Should this include line feed? What about carriage return?
			return content:gmatch("([^\n]*)\n?")
		end
		return lua_io.lines()
	end,
	open = function(filename, mode)
		assert.is_string(filename)
		local file = {
			_type = "file",
			_mode = 0, -- 0 = readonly, 1 = replace, 2 = truncate, 3 = noseek
			_read = false,
			_time = core.get_us_time and core.get_us_time() or 0,
			_path = normpath(filename),
			_fpos = 0,
		}
		-- FIXME: Check if file is valid, implement all modes properly
		local m = (mode or " "):gmatch(".")
		if type(fs[file._path]) ~= "table" and setmetatable({
				r = function()
					if m() == "+" or m() == "+" then
						file._mode = 1
					end
					file._read = true
					return type(fs[file._path]) == "string"
				end,
				a = function()
					if not fs[file._path] then
						fs[file._path] = ""
					end
					file._mode = 3
					file._fpos = #fs[file._path]
					return true
				end,
				w = function()
					fs[file._path] = ""
					file._mode = 2
					return true
				end,__index = function() error("(fake io) io.open unknown mode") end
			},{ __index = function(s,k) return rawget(s,k) or function() end end })[m()]() then
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
	local size = #fs[rawget(self, "_path")]
	if not rawget(self, "_read") then
		return nil, "EBADFD"
	elseif type(what) == "number" then
		if fpos + what <= size then
			local s = fs[rawget(self, "_path")]:sub(fpos + 1, fpos + what)
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
			return fs[rawget(self, "_path")]:sub(fpos + 1)
		elseif what == "*l" and size < 1 then
			return nil
		elseif what == "*l" then
			local s = fs[rawget(self, "_path")]:sub(fpos + 1):match("[^\n]*")
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
	if whence == nil then whence = "src" end
	if offset == nil then offset = 0 end
	assert.is_string(whence)
	assert.is_integer(offset)
	local newpos = 0
	if rawget(self, "_type") ~= "file" then
		return nil, "EBADFD"
	end
	if whence == "cur" then
		newpos = rawget(self, "_fpos") + offset
	elseif whence == "end" then
		newpos = #fs[rawget(self, "_path")]
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
	local size = #fs[rawget(self, "_path")]
	if mode == 0 then
		return nil, "EBADFD"
	elseif mode == 1 then
		-- Replace
		local s = table.concat({...})
		if #s >= size - fpos then
			-- Either both sides or last part can be ignored
			if fpos > 0 then
				fs[rawget(self, "_path")] = fs[rawget(self, "_path")]:sub(1,fpos)..s
			else
				fs[rawget(self, "_path")] = s
			end
		elseif fpos < 1 then
			-- Beginning can be ignored
			fs[rawget(self, "_path")] = s..fs[rawget(self, "_path")]:sub(#s+1)
		else
			-- Both sides are important
			fs[rawget(self, "_path")] = table.concat({
				fs[rawget(self, "_path")]:sub(1,fpos),s,fs[rawget(self, "_path")]:sub(#s+1)
			})
		end
	elseif mode == 2 and fpos < 1 then
		-- Truncate
		fs[rawget(self, "_path")] = table.concat({...})
	elseif mode == 2 then
		-- Truncate at fpos
		fs[rawget(self, "_path")] = table.concat({fs[rawget(self, "_path")]:sub(1,fpos),...})
	elseif mode == 3 then
		-- Append only
		fs[rawget(self, "_path")] = table.concat({fs[rawget(self, "_path")],...})
	else
		error("(fake io) Invalid file mode, this is probably a bug in Mineunit fs module.")
	end
	rawset(self, "_fpos", fpos + #fs[rawget(self, "_path")] - size)
	return true
end

File.__newindex = error

local normal_normpath = normpath
normpath = function(path)
	-- TODO: Empty path? Only parent ..?
	return path == "." and "." or normal_normpath(path)
end

function core.mkdir(path)
	path = normpath(path)
	if type(fs[path]) == "table" then
		return true
	elseif fs[path] == nil then
		fs[path] = {}
		return true
	end
	mineunit:warningf("(fake fs) core.mkdir: could not create directory: %s", path)
	return false
end

function core.get_dir_list(path, list_dirs)
	local results = {}
	local fsobj = fs[normpath(path)]
	if type(fsobj) ~= "table" then
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
	assert.not_table(fs[path])
	fs[path] = content
end

function mineunit:fs_reset()
	fs = {}
	fs["."] = fs
end

function mineunit:fs_copy(src, dst)
	if type(src) == "table" then
		for _, path in ipairs(src) do
			return mineunit:copy(path, dst)
		end
	else
		-- Copy real file into Mineunit fake fs
		dst = dst or src
		if dst:sub(-1) == DIR_DELIM then
			dst = dst .. basename(src)
		end
		if src:sub(1) ~= DIR_DELIM then
			src = mineunit:get_worldpath() .. DIR_DELIM .. src
		end
		local srcfile = mineunit:builtin("io").open(src, "rb")
		local dstfile = io.open(dst, "wb")
		dstfile:write(srcfile:read("*a"))
		srcfile:close()
		dstfile:close()
	end
end

end})[mineunit:config("use_real_fs") == true and "REAL FILESYSTEM" or "FAKE FILESYSTEM"]
