
local CM = mineunit('craftmanager')

mineunit.CraftManager = CM

-- TODO: Remove this one, still exposed just to avoid breaking too much at once
function mineunit.registered_craft_recipe(output, method)
	return CM:registered_craft_recipe(output, method)
end

function core.get_all_craft_recipes(output)
	assert.is_string(output, "core.get_all_craft_recipes(output): invalid output type, expected string")
	local results = {}
	for method, allcrafts in pairs(CM.registered_crafts) do
		for craftoutput, crafts in pairs(allcrafts) do
			if craftoutput == output then
				--for _, craft in ipairs(crafts) do
				for i = #crafts, 1, -1 do
					local craft = crafts[i]
					table.insert(results, {
						width = 0, -- FIXME: 0 means shapeless recipe
						type = method,
						items = CM.get_craft_items(craft),
						output = craft.output,
						method = method,
					})
				end
			end
		end
	end
	return #results > 0 and results or nil
end

local function has_groups(thing)
	if type(thing) == "string" then
		if thing:match("^group:") then
			return true
		end
	elseif type(thing) == "table" then
		for _,v in pairs(thing) do
			if has_groups(v) then
				return true
			end
		end
	elseif type(thing) == "userdata" then
		for _,v in pairs(thing) do
			if v:get_name():match("^group:") then
				return true
			end
		end
	else
		error("Invalid type in list")
	end
	return false
end

function core.register_craft(t)
	assert.is_table(t, "core.register_craft: table expected, got %s")
	t.type = t.type or "shaped"
	if t.type == "shaped" then
		assert.is_itemstring(t.output, "core.register_craft: t.output item name expected, got %s")
		assert.is_indexed(t.recipe, "core.register_craft: t.recipe indexed array expected, got %s")
		assert.is_true(#t.recipe > 0, "core.register_craft: expected t.recipe to contain at least one item")
		for i, row in ipairs(t.recipe) do
			assert.is_indexed(row, "core.register_craft: t.recipe["..i.."] indexed array expected, got %s")
			assert.is_true(#row > 0, "core.register_craft: expected t.recipe["..i.."] to contain at least one item")
		end
		if t.replacements ~= nil then
			-- assert.is_table(t.replacements)
		end
		local groups = has_groups(t.recipe)
		CM:registerCraft("shaped", groups and "PRIORITY_SHAPED_AND_GROUPS" or "PRIORITY_SHAPED", t.output, t)
	elseif t.type == "shapeless" then
		assert.is_itemstring(t.output, "core.register_craft: t.output item name expected, got %s")
		assert.is_indexed(t.recipe, "core.register_craft: t.recipe indexed array expected, got %s")
		assert.is_true(#t.recipe > 0)
		if t.replacements ~= nil then
			-- assert.is_table(t.replacements)
		end
		local groups = has_groups(t.recipe)
		CM:registerCraft("shapeless", groups and "PRIORITY_SHAPELESS_AND_GROUPS" or "PRIORITY_SHAPELESS", t.output, t)
	elseif t.type == "toolrepair" then
		if t.additional_wear ~= nil then
			assert.is_number(t.additional_wear, "core.register_craft: t.additional_wear number expected, got " .. type(t.additional_wear))
		end
		mineunit:warning("RECIPE TYPE toolrepair NOT REGISTERED", dump(t))
		-- TODO: Store registered toolrepair recipes
		--CM:registerCraft("toolrepair", error("TODO"), t.output, t)
	elseif t.type == "cooking" then
		assert.is_itemstring(t.output, "core.register_craft: t.output item name expected, got %s")
		assert.is_itemname(t.recipe, "core.register_craft: t.recipe item name expected, got %s")
		if t.cooktime ~= nil then
			assert.is_number(t.cooktime, "core.register_craft: t.cooktime number expected, got " .. type(t.cooktime))
		end
		t.cooktime = t.cooktime or 3
		if t.replacements then
			assert.is_indexed(t.replacements, "core.register_craft: t.replacements indexed table expected, got %s")
		end
		local groups = has_groups(t.recipe)
		CM:registerCraft("cooking", groups and "PRIORITY_SHAPELESS_AND_GROUPS" or "PRIORITY_SHAPELESS", t.output, t)
	elseif t.type == "fuel" then
		assert.is_string(t.recipe, "core.register_craft: t.recipe string expected, got " .. type(t.recipe))
		if t.burntime ~= nil then
			assert.is_number(t.burntime, "core.register_craft: t.burntime number expected, got " .. type(t.burntime))
		end
		t.burntime = t.burntime or 1
		local groups = has_groups(t.recipe)
		CM:registerCraft("fuel", groups and "PRIORITY_SHAPELESS_AND_GROUPS" or "PRIORITY_SHAPELESS", "", t)
	else
		error("Recipe type not supported: " .. tostring(t.type))
	end
end

function core.clear_craft(t)
	assert.is_table(t, "core.clear_craft: table expected, got %s")
	assert.not_nil(t.recipe or t.output, "core.clear_craft: recipe or output required")
	assert.is_nil(t.recipe and t.output, "core.clear_craft: please specify only recipe or output but not both")
end

local function is_ItemStack(obj)
	return mineunit.utils.type(obj) == "ItemStack"
end

local function to_ItemStacks(t)
	local results = {}
	for k, v in ipairs(t) do
		local stack = is_ItemStack(v) and v or (#v > 0 and ItemStack(v) or ItemStack(nil))
		table.insert(results, stack)
	end
	return results
end

local function items_empty(t)
	for _, stack in ipairs(t) do
		if not stack:is_empty() then
			return false
		end
	end
	return true
end

function core.get_craft_result(t)
	assert.is_hashed(t, "core.get_craft_result: hash table expected, got %s")
	if t.method ~= nil then
		assert.in_array(t.method, {"normal","cooking","fuel"}, "core.get_craft_result: t.method invalid value")
	end
	assert.is_table(t.items, "core.get_craft_result: t.items table expected, got %s")
	assert(#t.items > 0, "core.get_craft_result: t.items is empty")

	local input = {
		type = t.method or "normal",
		method = t.method or "normal",
		width = t.width or 0,
		items = to_ItemStacks(t.items),
	}

	local result
	if not items_empty(input.items) then
		result = CM:getCraftResult(input, true)
	end
	result = result or {
		item = ItemStack(nil),
		time = 0,
	}
	result.replacements = result.replacements or {}

	local leftover = {
		method = input.method,
		width = input.width,
		items = input.items,
	}

	return result, leftover
end
