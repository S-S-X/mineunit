
-- For self tests package path must be set in a way that makes package loaders search current directory first
package.path = "./?.lua;../?/init.lua;../?.lua;" --.. package.path

describe("ItemStack", function()

	require("mineunit")
	sourcefile("itemstack")
	mineunit("assert")

	core.registered_items = {
		test = { stack_max = 100 }
	}

	describe("wear", function()

		it("set_wear 0", function()
			local stack = ItemStack("test")
			stack:set_wear(0)
			assert.equals(0, stack:get_wear())
		end)

		it("set_wear 1", function()
			local stack = ItemStack("test")
			stack:set_wear(1)
			assert.equals(1, stack:get_wear())
		end)

		it("set_wear -1", function()
			local stack = ItemStack("test")
			stack:set_wear(-1)
			assert.equals(65535, stack:get_wear())
		end)

		it("set_wear -65535", function()
			local stack = ItemStack("test")
			stack:set_wear(-65535)
			assert.equals(1, stack:get_wear())
		end)

		it("set_wear -65536", function()
			local stack = ItemStack("test")
			stack:set_wear(-65536)
			assert.equals(0, stack:get_wear())
		end)

		it("set_wear -65537", function()
			local stack = ItemStack("test")
			stack:set_wear(-65537)
			assert.equals(65535, stack:get_wear())
		end)

		it("set_wear 65537", function()
			local stack = ItemStack("test")
			assert.has_error(function()
				stack:set_wear(65537)
			end)
		end)

	end)

	describe("get_count", function()

		it("stack size zero", function()
			local stack = ItemStack()
			assert.equals(0, stack:get_count())
		end)

		it("stack size one, itemstring", function()
			local stack = ItemStack("test")
			assert.equals(1, stack:get_count())
		end)

		it("stack size zero, itemstring with count", function()
			local stack = ItemStack("test 0")
			assert.equals(0, stack:get_count())
		end)

		it("stack size one, itemstring with count", function()
			local stack = ItemStack("test 1")
			assert.equals(1, stack:get_count())
		end)

		it("oversized stack size 111, itemstring with count", function()
			local stack = ItemStack("test 111")
			assert.equals(111, stack:get_count())
		end)

	end)

	describe("add_item", function()

		it("add_item to empty stack", function()
			local stack = ItemStack("test 0")
			local leftover = stack:add_item(ItemStack("test 3"))
			assert.equals(3, stack:get_count())
			assert.equals(0, leftover:get_count())
		end)

		it("add_item to default stack size", function()
			local stack = ItemStack("test")
			local leftover = stack:add_item(ItemStack("test 3"))
			assert.equals(4, stack:get_count())
			assert.equals(0, leftover:get_count())
		end)

		it("add_item to max stack size", function()
			local stack = ItemStack("test 100")
			local leftover = stack:add_item(ItemStack("test 3"))
			assert.equals(100, stack:get_count())
			assert.equals(3, leftover:get_count())
		end)

		it("add_item to max - 1 stack size", function()
			local stack = ItemStack("test 99")
			local leftover = stack:add_item(ItemStack("test 3"))
			assert.equals(100, stack:get_count())
			assert.equals(2, leftover:get_count())
		end)

		it("add_item to max + 1 stack size", function()
			local stack = ItemStack("test 101")
			local leftover = stack:add_item(ItemStack("test 3"))
			assert.equals(101, stack:get_count())
			assert.equals(3, leftover:get_count())
		end)

	end)

	describe("stack definition", function()

		it("is_known known itemstring", function()
			local result = ItemStack("test"):is_known()
			assert.is_true(result)
		end)

		it("is_known unknown itemstring", function()
			local result = ItemStack("testunknown"):is_known()
			assert.is_false(result)
		end)

		it("get_definition", function()
			local result = ItemStack("test"):get_definition()
			assert.equals(core.registered_items["test"], result)
		end)

	end)

end)
