--
-- Wrappers and helpers for print
--

local luaprint = _G.print
local luatype = mineunit.utils and mineunit.utils.luatype or _G.type
local debug = debug

-- Used in case engine core libraries have not been loaded yet
function dump(thing)
	return require('luassert.state').format_argument(thing) or tostring(thing)
end

function mineunit:prepend_print(s)
	self._prepend_output = s
end

function mineunit:prepend_flush()
	if self._prepend_output then
		io.stdout:write(self._prepend_output)
		self._prepend_output = nil
	end
end

local function printwrapper(...)
	mineunit:prepend_flush()
	luaprint(...)
end

local formatters = {
	["nil"] = tostring,
	["xnil"] = tostring,
	["function"] = tostring,
	["xfunction"] = tostring,
	["userdata"] = tostring,
	["xuserdata"] = tostring,
	--luacheck: push ignore 561 cyclomatic complexity
	["table"] = function(thing)
		local above = rawget(thing, "above")
		local under = rawget(thing, "under")
		if luatype(under) == "table" or luatype(above) == "table" then
			local thingtype = rawget(thing, "type")
			local ref = rawget(thing, "ref")
			return "{"..
				(thingtype ~= nil and "\n\ttype = "..tostring(thingtype) or "")..
				(above ~= nil and "\n\tabove = "..(above
					and "{x="..above.x..",y="..above.y..",z="..above.z.."}"
					or tostring(above)
				) or "")..
				(under ~= nil and "\n\tunder = "..(under
					and "{x="..under.x..",y="..under.y..",z="..under.z.."}"
					or tostring(under)
				) or "")..
				(ref ~= nil and "\n\tref = "..tostring(ref) or "")
				.."\n}"
		elseif mineunit.utils.is_coordinate(thing) then
			return mineunit.utils.format_coordinate(thing)
		end
		return tostring(thing)
	end,
	--luacheck: pop
	["xtable"] = tostring,
	["number"] = tostring,
	["xnumber"] = function(d) return ("%x"):format(d) end,
	["string"] = tostring,
	["xstring"] = function(s)
		return s:gsub("(.)(.?)", function(a,b)
			return b == "" and ("%02x"):format(a:byte()) or ("%02x%02x "):format(a:byte(),b:byte())
		end)
	end,
	["boolean"] = tostring,
	["xboolean"] = function(b) return b and "1" or "0" end,
}

local function fmtargs(s)
	local pos, _, ch = 0
	return function()
		pos, _, ch = s:find("%%([sx@t])", pos + 1)
		return pos, ch
	end
end

local function formatter(fmtstr, ...)
	local args = {...}
	local matcher = fmtargs(fmtstr)
	local index = 0
	for pos, argtype in matcher do
		index = index + 1
		local t = luatype(args[index])
		if formatters[t] then
			if argtype == "s" then
				args[index] = formatters[t](args[index])
			elseif argtype == "x" then
				args[index] = formatters["x"..t](args[index])
			elseif argtype == "t" then
				args[index] = dump(args[index])
			elseif argtype == "@" then
				local level = (tonumber(fmtstr:sub(pos + 1, pos + 1)) or 0) + 4
				local trace = debug.getinfo(level, "Sl")
				table.insert(args, index, trace.source:sub(2) .. ":" .. tostring(trace.currentline))
			end
		end
	end
	return fmtstr:gsub("%%[tx@]", "%%s"):format(unpack(args))
end

local function fmtprint(fmtstr, ...)
	return printwrapper(formatter(fmtstr, ...))
end

function mineunit:debug(...)   if self:config("verbose") > 3 then printwrapper("D:",...) end end
function mineunit:info(...)    if self:config("verbose") > 2 then printwrapper("I:",...) end end
function mineunit:warning(...) if self:config("verbose") > 1 then printwrapper("W:",...) end end
function mineunit:error(...)   if self:config("verbose") > 0 then printwrapper("E:",...) end end
function mineunit:print(...)   if self:config("print")       then printwrapper(...) end end

function mineunit:debugf(fmtstr, ...)   if self:config("verbose") > 3 then fmtprint("D: "..fmtstr,...) end end
function mineunit:infof(fmtstr, ...)    if self:config("verbose") > 2 then fmtprint("I: "..fmtstr,...) end end
function mineunit:warningf(fmtstr, ...) if self:config("verbose") > 1 then fmtprint("W: "..fmtstr,...) end end
function mineunit:errorf(fmtstr, ...)   if self:config("verbose") > 0 then fmtprint("E: "..fmtstr,...) end end
function mineunit:printf(fmtstr, ...)   if self:config("print")       then fmtprint(fmtstr,...) end end
mineunit.format = formatter

_G.print = function(...) mineunit:print(...) end
