-- Globals defined by Minetest
--
-- For more information see following source files:
-- https://github.com/minetest/minetest/blob/master/src/script/cpp_api/s_base.cpp
-- https://github.com/minetest/minetest/blob/master/src/porting.h

-- Data

local registered_crafts = {
	normal = {},
	cooking = {},
	fuel = {}
}
function mineunit.registered_craft_recipe(output, method)
	local crafts = registered_crafts[method or "normal"][output]
	return crafts and crafts[1] and crafts[1].recipe
end

local function push_craft(method, output, data)
	if not registered_crafts[method][output] then
		registered_crafts[method][output] = {}
	end
	table.insert(registered_crafts[method][output], data)
end

local function recipe_to_craft(method, recipe)
	for output, crafts in pairs(registered_crafts[method]) do
		for _, craft in ipairs(crafts) do
			if craft.recipe == recipe then
				return craft
			end
		end
	end
end

-- Libraries

local assert = require('luassert.assert')

-- Constants

os.setlocale("C")
INIT = "client"
PLATFORM = "Linux"
DIR_DELIM = "/"

-- Engine API

local core = {}
_G.core = core

function core.global_exists(name)
	return rawget(_G, name) ~= nil
end

function core.log(level, ...)
	if level == "error" then
		mineunit:error(...)
	elseif level == "warning" then
		mineunit:warning(...)
	elseif level == "debug" then
		mineunit:debug(...)
	else
		mineunit:info(...)
	end
end
function core.request_http_api(...) end

function core.gettext(value)
	assert.is_string(value, "core.gettext: expected string, got " .. type(value))
	return value
end

function core.get_timeofday()
	return 0.5
end

function core.get_node_light(pos, timeofday)
	timeofday = timeofday or 0.5
	return mineunit.utils.round(math.sin(timeofday * 3.14) * 15)
end

local json = require('mineunit.lib.json')

function core.write_json(...)
	local args = {...}
	local success, result = pcall(function() return json.encode(unpack(args)) end)
	return success and result or nil
end

function core.parse_json(...)
	local args = {...}
	local success, result = pcall(function() return json.decode(unpack(args)) end)
	return success and result or nil
end

function core.register_craft(t)
	assert.is_table(t, "core.register_craft: table expected, got " .. type(t))
	if t.type == nil then
		assert.is_string(t.output, "core.register_craft: t.output string expected, got " .. type(t.output))
		assert.is_indexed(t.recipe, "core.register_craft: t.recipe indexed array expected, got " .. type(t.recipe))
		push_craft("normal", t.output, t)
	elseif t.type == "shapeless" then
		assert.is_string(t.output, "core.register_craft: t.output string expected, got " .. type(t.output))
		assert.is_indexed(t.recipe, "core.register_craft: t.recipe indexed array expected, got " .. type(t.recipe))
		push_craft("normal", t.output, t)
	elseif t.type == "toolrepair" then
		if t.additional_wear ~= nil then
			assert.is_number(t.additional_wear, "core.register_craft: t.additional_wear number expected, got " .. type(t.additional_wear))
		end
		mineunit:warning("RECIPE TYPE toolrepair NOT SAVED", dump(t))
		-- TODO: Store registered toolrepair recipes
	elseif t.type == "cooking" then
		assert.is_string(t.output, "core.register_craft: t.output string expected, got " .. type(t.output))
		assert.is_string(t.recipe, "core.register_craft: t.recipe string expected, got " .. type(t.recipe))
		if t.cooktime ~= nil then
			assert.is_number(t.cooktime, "core.register_craft: t.cooktime number expected, got " .. type(t.cooktime))
		end
		t.cooktime = t.cooktime or 3
		if t.replacements then
			assert.is_indexed(t.replacements, "core.register_craft: t.replacements indexed table expected, got " .. type(t.replacements))
		end
		push_craft("cooking", t.output, t)
	elseif t.type == "fuel" then
		assert.is_string(t.recipe, "core.register_craft: t.recipe string expected, got " .. type(t.recipe))
		if t.burntime ~= nil then
			assert.is_number(t.burntime, "core.register_craft: t.burntime number expected, got " .. type(t.burntime))
		end
		t.burntime = t.burntime or 1
		push_craft("fuel", t.burntime, t)
	else
		error("Recipe type not supported: " .. tostring(t.type))
	end
end

function core.clear_craft(t)
	assert.is_table(t, "core.clear_craft: table expected, got " .. type(t))
	assert.not_nil(t.recipe or t.output, "core.clear_craft: recipe or output required")
	assert.is_nil(t.recipe and t.output, "core.clear_craft: please specify only recipe or output but not both")
end

local function is_ItemStack(obj)
	return mineunit.utils.type(obj) == "ItemStack"
end

function core.get_craft_result(t)
	assert.is_hashed(t, "core.get_craft_result: hash table expected, got " .. type(t))
	if t.method ~= nil then
		assert.in_array(t.method, {"normal","cooking","fuel"}, "core.get_craft_result: t.method invalid value")
	end
	t.method = t.method or "normal"
	assert.is_table(t.items, "core.get_craft_result: t.items table expected, got " .. type(t.items))
	if not is_ItemStack(t.items) then
		assert(#t.items > 0, "core.get_craft_result: t.items is empty")
		for k, v in ipairs(t.items) do
			assert.is_ItemStack(v, "core.get_craft_result: t.items["..k.."] ItemStack expected")
			--assert(#v:get_name() > 0, "core.get_craft_result: t.items["..k.."] invalid ItemStack")
			if #v:get_name() == 0 then
				return
			end
		end
	else
		if #t.items:get_name() == 0 then
			return
		end
	end
	local items = is_ItemStack(t.items) and {t.items} or t.items
	for _, item in ipairs(items) do
		assert.is_ItemStack(item, "core.get_craft_result: invalid item type in items, ItemStack expected")
		local craft = recipe_to_craft(t.method, item:get_name())
		if craft then
			local new_input = ItemStack(item)
			new_input:set_count(new_input:get_count()-1)
			return
				{
					item = ItemStack(craft.output),
					time = craft.cooktime,
					replacements = craft.replacements or {},
				},
				{
					items = {
						new_input
					},
					method = t.method,
					width = 1
				}
		end
	end
	error("core.get_craft_result failed, input was: "..dump(t))
	return {
		item = ItemStack(),
		time = 0,
		replacements = nil,
		decremented_input = {
			items = ItemStack()
		}
	}
end

function core.get_dig_params(groups, capabilities, initial_wear)
	assert.is_table(groups, "core.get_dig_params groups table expected, got: "..type(groups))
	assert.is_table(capabilities, "core.get_dig_params capabilities table expected, got: "..type(capabilities))
	if initial_wear ~= nil then
		assert.is_number(initial_wear, "core.get_dig_params initial_wear number expected, got: "..type(initial_wear))
	end

	local groupcaps = capabilities.groupcaps
	if groupcaps.dig_immediate then
		if groups.dig_immediate == 2 then
			return { diggable = true, time = 0.5, wear = 0 }
		elseif groups.dig_immediate == 3 then
			return { diggable = true, time = 0, wear = 0 }
		end
	end

	local diggable = false
	local result_time = 0
	local wear = 0
	for groupname, cap in pairs(groupcaps) do
		local level = groups.level
		local leveldiff = cap.maxlevel - level
		if leveldiff >= 0 then
			if cap.times and cap.times[groups[groupname]] then
				local time = 0
				if leveldiff > 1 then
					time = time / leveldiff
				end
				if not diggable or time < 0 then
					-- Basic parameter
					result_time = time
					diggable = true
					-- Calculate tool wear
					local real_uses = math.min(cap.uses * math.pow(3, leveldiff), 65535)
					local wear = 65536 / real_uses
					local additional = 65536 % real_uses
					if additional > 0 then
						if initial_wear >= (real_uses - additional) * wear then
							wear = wear + 1
						end
					end
				end
			end
		end
	end
	return { diggable = diggable, time = result_time, wear = wear }
end

local origin
function core.get_last_run_mod() return origin end
function core.set_last_run_mod(v) origin = v end
