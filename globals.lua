-- Globals defined by Minetest
--
-- For more information see following source files:
-- https://github.com/minetest/minetest/blob/master/src/script/cpp_api/s_base.cpp
-- https://github.com/minetest/minetest/blob/master/src/porting.h

-- Data

local registered_crafts = {}
function mineunit.registered_craft_recipe(key)
	return registered_crafts[key] and registered_crafts[key].recipe
end

-- Libraries

local assert = require('luassert.assert')

-- Constants

os.setlocale("C")
PLATFORM = "Linux"
DIR_DELIM = "/"

-- Engine API

_G.core = {}
_G.core.log = function(...) mineunit:info(...) end
_G.core.request_http_api = function(...) end

_G.core.register_craft = function(t)
	-- FIXME: Behavior is incorrect for some inputs, missing functionality
	assert.is_table(t, "core.register_craft: table expected, got " .. type(t))
	assert.is_string(t.output, "core.register_craft: t.output string expected, got " .. type(t.output))
	assert.is_indexed(t.recipe, "core.register_craft: t.recipe indexed array expected, got " .. type(t.recipe))
	registered_crafts[t.output] = t
end

_G.core.clear_craft = function(t)
	assert.is_table(t, "core.clear_craft: table expected, got " .. type(t))
	assert.not_nil(t.output or t.input, "core.clear_craft: input or output required")
	assert.is_nil(t.output and t.input, "core.clear_craft: please specify only input or output but not both")
end

local origin
_G.core.get_last_run_mod = function() return origin end
_G.core.set_last_run_mod = function(v) origin = v end
