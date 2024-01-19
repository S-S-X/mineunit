-- Spec: https://github.com/minetest/minetest/blob/master/src/craftdef.cpp

--
-- Utilities and some definitions
--

local bit = require("bit")

local function init_lookup_table(values)
	local result = {}
	for index, name in ipairs(values) do
		result[name] = index
		result[index] = name
	end
	setmetatable(result, {
		__newindex = error,
		__index = error,
	})
	return result
end

local RecipePriority = init_lookup_table({
	"PRIORITY_NO_RECIPE", "PRIORITY_TOOLREPAIR",
	"PRIORITY_SHAPELESS_AND_GROUPS", "PRIORITY_SHAPELESS",
	"PRIORITY_SHAPED_AND_GROUPS", "PRIORITY_SHAPED",
})

-- TODO: Use this for methods to prevent mistakes (it is already messed up, needs some work to clean up methods)
--local CraftMethod = init_lookup_table({
--	"CRAFT_METHOD_NORMAL", "CRAFT_METHOD_COOKING", "CRAFT_METHOD_FUEL",
--})

local CRAFT_HASH_TYPE_MAX = 1 -- FIXME: Implement HASH_TYPE_COUNT and increase this number
local HASH_TYPE_NAME = 1
local HASH_TYPE_COUNT = 2

local function getHashForGrid(hash_type, input_names)
	if hash_type == HASH_TYPE_NAME then
		local h = 0
		for _, name in ipairs(input_names) do
			h = h + #name
			for c in name:gmatch(".") do
				h = bit.bxor(h, bit.lshift(h, 5) + bit.rshift(h, 2) + c:byte())
			end
			h = bit.bxor(h, bit.lshift(h, 5) + bit.rshift(h, 2) + 10)
		end
		return h
	elseif hash_type == HASH_TYPE_COUNT then
		local count = 0
		for _, name in ipairs(input_names) do
			if name ~= "" then
				count = count + 1
			end
		end
		return count
	end
	return 0
end

local function insert_all_flat(t, src)
	if type(src) == "userdata" then
		table.insert(t, src:get_name())
	elseif type(src) == "string" then
		table.insert(t, src)
	elseif type(src) == "table" then
		for _, value in ipairs(src) do
			insert_all_flat(t, value)
		end
	else
		error("Invalid type in list")
	end
	return t
end

local function ensuretable(t, key)
	if t[key] == nil then
		t[key] = {}
	end
	assert(type(t[key] == "table"))
	return t[key]
end

local function decrement_input(input)
	for _,item in pairs(input.items) do
		item:set_count(item:get_count() - 1)
	end
	-- FIXME: Should return replacements, see craftDecrementOrReplaceInput
	return {}
end

--
-- CraftManager
--

local CraftManager = {}

-- @CraftInput input
-- TODO: @ItemStack[] output_replacements Craft replacements not implemented, possibly return value
-- @bool decrementInput
-- @return @CraftOutput|nil
function CraftManager:getCraftResult(input, decrementInput)
	--local input_names = table.sort(insert_all_flat({}, input.items))
	local input_names = insert_all_flat({}, input.items)
	local priority_best = RecipePriority.PRIORITY_NO_RECIPE
	local output

	for hash_type = 1, CRAFT_HASH_TYPE_MAX, 1 do -- @CraftHashType
		local hash = getHashForGrid(hash_type, input_names)
		local hash_collisions = self.hashed_crafts[hash_type][hash] or {}

		for i = #hash_collisions, 1, -1 do
			local def = hash_collisions[i] -- @CraftDefinition
			local priority = assert(def._recipe_priority) -- @RecipePriority

			if priority > priority_best --[[ FIXME: Check input recipe compatibility: and def:check(input) ]] then
				local out = { item = def.output, time = def.time or def.cooktime or 0 }
				assert(out.item) -- Not inlined because assert seems to return 3 arguments where last two are nil
				out.item = ItemStack(out.item)
				if out.item:is_known() then
					output = out
					priority_best = priority
				else
					mineunit:warning("trying to craft non-existent " .. out.item .. ", ignoring recipe")
				end
			end
		end
	end

	if output and decrementInput then
		output.replacements = decrement_input(input)
	end
	return output
end

-- @CraftOutput output
-- @unsigned limit = 0
-- @return \CraftDefinition[]
function CraftManager:getCraftRecipes(output, limit)
	limit = limit or 0
end

-- @CraftOutput output
-- @return \bool
function CraftManager:clearCraftsByOutput(output)
end

-- @CraftInput input
-- @return \bool
function CraftManager:clearCraftsByInput(input)
end

-- @return \string
function CraftManager:dump()
	return dump(self.registered_crafts)
end

-- @string method
-- @string priority TODO: Allow number
-- @string output
-- @CraftDefinition def
-- @return \nil
function CraftManager:registerCraft(method, priority, output, def)
	-- Get name without additional stack data
	local outname = method == "fuel" and def.burntime or output:match("^%S+")
	def._recipe_priority = assert(RecipePriority[priority])
	if not self.registered_crafts[method][outname] then
		self.registered_crafts[method][outname] = {}
	end
	table.insert(self.registered_crafts[method][outname], def)
	-- FIXME: Hashing should be done after mods been loaded and before globalstep starts
	local hc = self.hashed_crafts
	local items = self.get_craft_items(def)
	table.insert(ensuretable(hc[HASH_TYPE_NAME], getHashForGrid(HASH_TYPE_NAME, items)), def)
	table.insert(ensuretable(hc[HASH_TYPE_COUNT], getHashForGrid(HASH_TYPE_COUNT, items)), def)
end

-- @return \nil
function CraftManager:clear()
	-- FIXME: Quick and easy but not good
	self.registered_crafts = {
		shaped = {},
		shapeless = {},
		toolrepair = {},
		cooking = {},
		fuel = {},
	}
	-- Alias normal -> shaped
	self.registered_crafts.normal = self.registered_crafts.shaped
	-- Create table for craft hashes, each sub table represents priority for hash type
	self.hashed_crafts = {{},{},{}}
end

-- @return \nil
function CraftManager:initHashes()
end

-- Utility functions

function CraftManager:recipe_to_craft(method, recipe)
	for output, crafts in pairs(self.registered_crafts[method]) do
		for _, craft in ipairs(crafts) do
			if craft.recipe == recipe then
				return craft
			end
		end
	end
end

function CraftManager.get_craft_items(craft)
	-- TODO: Add assertions based on recipe type, maybe hide this function?
	return insert_all_flat({}, craft.recipe)
end

function CraftManager:registered_craft_recipe(output, method)
	local crafts = self.registered_crafts[method or "normal"][output]
	return crafts and crafts[1] and crafts[1].recipe
end

function CraftManager:registered_craft(output, method)
	local crafts = self.registered_crafts[method or "normal"][output]
	return crafts and crafts[1] or nil
end

mineunit.export_object(CraftManager, {
	name = "CraftManager",
	private = true,
	constructor = function(self)
		local obj = {}
		setmetatable(obj, CraftManager)
		obj:clear()
		return obj
	end,
})

return CraftManager()
