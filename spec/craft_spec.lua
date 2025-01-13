-- For self tests package path must be set in a way that makes package loaders search current directory first
package.path = "./?.lua;../?/init.lua;../?.lua;" --.. package.path

describe("Craft API", function()

	require("mineunit")
	mineunit:config_set("silence_global_export_overrides", true)
	sourcefile("core")
	sourcefile("itemstack")
	sourcefile("entity")
	sourcefile("player")
	fixture("items")

	local CM = mineunit.CraftManager

	minetest.register_craft({
		output = 'bridge',
		recipe = {
			{'stone', 'stone', 'stone'}
		}
	})

	minetest.register_craft({
		output = 'cross',
		recipe = {
			{'stone', 'stone', 'stone'},
			{'',      'stone', ''},
			{'',      'stone', ''},
		}
	})

	describe("get_all_craft_recipes", function()

		it("returns nil without matches", function()
			local result = core.get_all_craft_recipes("testunknown")
			assert.is_nil(result)
		end)

		it("returns matching recipes", function()
			local result = core.get_all_craft_recipes("wood")
			assert.is_table(result)
		end)

	end)

	describe("get_craft_result", function()

		it("throws without arguments", function()
			assert.has_error(function() core.get_craft_result() end)
		end)

		it("throws without without items", function()
			assert.has_error(function()
				core.get_craft_result({
					method = "normal",
					width = 1,
				})
			end)
		end)

		it("throws without with invalid items", function()
			assert.has_error(function()
				core.get_craft_result({
					method = "normal",
					width = 1,
					items = "wood",
				})
			end)
		end)

		it("does not modify input for string items", function()
			local input = {
				method = "normal",
				width = 3,
				items = {
					"tree 1"
				},
			}
			local expected_address = tostring(input)
			local expected_result = table.copy(input)
			core.get_craft_result(input)
			-- Compare table address
			assert.equals(expected_address, tostring(input))
			assert.same(expected_result, input)
		end)

		it("does not modify input for ItemStack items", function()
			local input = {
				method = "normal",
				width = 3,
				items = {
					ItemStack("tree 1")
				},
			}
			local expected_address = tostring(input)
			local expected_result = table.copy(input)
			core.get_craft_result(input)
			-- Compare table address
			assert.equals(expected_address, tostring(input))
			assert.same(expected_result, input)
		end)

		it("returns results", function()
			local input = {
				method = "normal",
				width = 3,
				items = {
					ItemStack("tree 1")
				},
			}
			local expected_result = {
				time = 0,
				replacements = {},
				item = ItemStack("wood 4")
			}
			local expected_leftover = {
				width = 3,
				items = {
					ItemStack(nil)
				},
				method = "normal"
			}
			local result, leftover = core.get_craft_result(input)
			assert.same(expected_result, result)
			assert.same(expected_leftover, leftover)
		end)

	end)

end)
