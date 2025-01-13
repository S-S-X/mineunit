--
-- Wrappers and helpers for print
--

local luaprint = _G.print
local luatype = mineunit.utils and mineunit.utils.luatype or _G.type

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
	["table"] = function(thing)
		if luatype(thing.under) == "table" or luatype(thing.above) == "table" then
			return "{"..
				(thing.type ~= nil and "\n\ttype = "..tostring(thing.type) or "")..
				(thing.above ~= nil and "\n\tabove = "..(thing.above
					and "{x="..thing.above.x..",y="..thing.above.y..",z="..thing.above.z.."}"
					or tostring(thing.above)
				) or "")..
				(thing.under ~= nil and "\n\tunder = "..(thing.under
					and "{x="..thing.under.x..",y="..thing.under.y..",z="..thing.under.z.."}"
					or tostring(thing.under)
				) or "")..
				(thing.ref ~= nil and "\n\tref = "..tostring(thing.ref) or "")
				.."\n}"
		elseif mineunit.utils.is_coordinate(thing) then
			return "{x="..thing.x..",y="..thing.y..",z="..thing.z.."}"
		end
		return tostring(thing)
	end,
	["xtable"] = tostring,
	["number"] = tostring,
	["xnumber"] = tostring,
	["boolean"] = tostring,
	["xboolean"] = tostring,
}

local function fmtprint(fmtstr, ...)
	local args = {...}
	local matcher = fmtstr:gmatch("%%(.)")
	local index = 0
	for argtype in matcher do
		index = index + 1
		local t = luatype(args[index])
		if formatters[t] then
			if argtype == "s" then
				args[index] = formatters[t](args[index])
			elseif argtype == "x" then
				args[index] = formatters["x"..t](args[index])
			elseif argtype == "t" then
				args[index] = dump(args[index])
			end
		end
	end
	return printwrapper(fmtstr:gsub("%%t", "%%s"):format(unpack(args)))
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

_G.print = function(...) mineunit:print(...) end
