--
-- Wrappers and helpers for print
--

local luaprint = _G.print

function mineunit:prepend_print(s)
	self._append_output = s
end

function mineunit:prepend_flush()
	if self._append_output then
		io.stdout:write(self._append_output)
		self._append_output = nil
	end
end

local function printwrapper(...)
	mineunit:prepend_flush()
	luaprint(...)
end

function mineunit:debug(...)   if self:config("verbose") > 3 then printwrapper("D:",...) end end
function mineunit:info(...)    if self:config("verbose") > 2 then printwrapper("I:",...) end end
function mineunit:warning(...) if self:config("verbose") > 1 then printwrapper("W:",...) end end
function mineunit:error(...)   if self:config("verbose") > 0 then printwrapper("E:",...) end end
function mineunit:print(...)   if self:config("print")       then printwrapper(...) end end

_G.print = function(...) mineunit:print(...) end
