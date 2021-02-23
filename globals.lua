-- Globals defined by Minetest
--
-- For more information see following source files:
-- https://github.com/minetest/minetest/blob/master/src/script/cpp_api/s_base.cpp
-- https://github.com/minetest/minetest/blob/master/src/porting.h

os.setlocale("C")
PLATFORM = "Linux"
DIR_DELIM = "/"

_G.core = {}
_G.core.log = function(...) mineunit:info(...) end
_G.core.request_http_api = function(...) end
