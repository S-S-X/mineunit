local File = {}
File.__index = File

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
	local fs = rawget(self, "_fsys")
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
		local fs = rawget(self, "_fsys")
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
	local fs = rawget(self, "_fsys")
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

-- Return fs bound constructor factory for creating File instances
return function(fs)
	return function(path, mode)
		local file = {
			_fsys = fs,
			_type = "file",
			_mode = 0, -- 0 = readonly, 1 = replace, 2 = truncate, 3 = noseek
			_read = false,
			_time = core.get_us_time and core.get_us_time() or 0,
			_path = path,
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
					local data, parent, fpath = fs:get(file._path)
					if data == nil then
						parent[fpath] = ""
					end
					file._mode = 3
					file._fpos = #parent[fpath]
					return true
				end,
				w = function()
					fs:set(file._path, "")
					file._mode = 2
					return true
				end,__index = function() error("(fake io) io.open unknown mode") end
			},{ __index = function(s,k) return rawget(s,k) or function() end end })[m()]() then
			setmetatable(file, File)
			return file
		end
		return nil, "ENOENT"
	end
end