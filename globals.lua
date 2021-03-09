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
	assert.is_table(t, "core.register_craft: table expected, got " .. type(t))
	if t.type == nil then
		assert.is_string(t.output, "core.register_craft: t.output string expected, got " .. type(t.output))
		assert.is_indexed(t.recipe, "core.register_craft: t.recipe indexed array expected, got " .. type(t.recipe))
		registered_crafts[t.output] = t
	elseif t.type == "shapeless" then
		assert.is_string(t.output, "core.register_craft: t.output string expected, got " .. type(t.output))
		assert.is_indexed(t.recipe, "core.register_craft: t.recipe indexed array expected, got " .. type(t.recipe))
		registered_crafts[t.output] = t
	elseif t.type == "toolrepair" then
		if t.additional_wear ~= nil then
			assert.is_number(t.additional_wear, "core.register_craft: t.additional_wear number expected, got " .. type(t.additional_wear))
		end
		-- TODO: Store registered toolrepair recipes
	elseif t.type == "cooking" then
		assert.is_string(t.output, "core.register_craft: t.output string expected, got " .. type(t.output))
		assert.is_string(t.recipe, "core.register_craft: t.recipe string expected, got " .. type(t.recipe))
		if t.cooktime ~= nil then
			assert.is_number(t.cooktime, "core.register_craft: t.cooktime number expected, got " .. type(t.cooktime))
		end
		if t.replacements then
			assert.is_indexed(t.replacements, "core.register_craft: t.replacements indexed table expected, got " .. type(t.replacements))
		end
		-- TODO: Store registered cooking recipes
	elseif t.type == "fuel" then
		assert.is_string(t.recipe, "core.register_craft: t.recipe string expected, got " .. type(t.recipe))
		if t.burntime ~= nil then
			assert.is_number(t.burntime, "core.register_craft: t.burntime number expected, got " .. type(t.burntime))
		end
		-- TODO: Store registered fuel recipes
	else
		error("Recipe type not supported: " .. tostring(t.type))
	end
end

_G.core.clear_craft = function(t)
	assert.is_table(t, "core.clear_craft: table expected, got " .. type(t))
	assert.not_nil(t.recipe or t.output, "core.clear_craft: recipe or output required")
	assert.is_nil(t.recipe and t.output, "core.clear_craft: please specify only recipe or output but not both")
end

local origin
_G.core.get_last_run_mod = function() return origin end
_G.core.set_last_run_mod = function(v) origin = v end
