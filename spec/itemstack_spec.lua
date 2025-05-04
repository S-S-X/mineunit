
-- For self tests package path must be set in a way that makes package loaders search current directory first
package.path = "./?.lua;../?/init.lua;../?.lua;" --.. package.path

describe("ItemStack", function()

	require("mineunit")
	mineunit:config_set("silence_global_export_overrides", true)
	sourcefile("itemstack")

	core.registered_items = {
		test = { stack_max = 100 }
	}

	describe("constructor", function()

		it("fails ItemStack()", function()
			pending("Waiting for strict mode implementation")
			local stack
			assert.has_error(function()
				stack = ItemStack()
			end)
			assert.is_nil(stack)
		end)

		it("fails ItemStack('')", function()
			local stack
			assert.has_error(function()
				stack = ItemStack('')
			end)
			assert.is_nil(stack)
		end)

		it("fails ItemStack('  ')", function()
			local stack
			assert.has_error(function()
				stack = ItemStack('  ')
			end)
			assert.is_nil(stack)
		end)

		it("allows ItemStack(nil)", function()
			local stack
			assert.no_error(function()
				stack = ItemStack(nil)
			end)
			assert.is_ItemStack(stack)
		end)

		it("allows ItemStack('testunknown')", function()
			local stack
			assert.no_error(function()
				stack = ItemStack('testunknown')
			end)
			assert.is_ItemStack(stack)
		end)

		it("allows ItemStack('test')", function()
			local stack
			assert.no_error(function()
				stack = ItemStack('test')
			end)
			assert.is_ItemStack(stack)
		end)

	end)

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
			local stack = ItemStack(nil)
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

		it("add_item get_free_space", function()
			local stack = ItemStack("test 40")
			stack:add_item(ItemStack("test 9"))
			assert.equals(51, stack:get_free_space())
		end)

		it("add_item unknown get_free_space", function()
			local stack = ItemStack("testunknown 40")
			stack:add_item(ItemStack("testunknown 9"))
			assert.equals(50, stack:get_free_space())
		end)

	end)

	describe("to_table", function()

		it("returns all data", function()
			local stack = ItemStack("test 101")
			stack:set_wear(1337)
			local meta = stack:get_meta()
			meta:set_string("foo", "bar")
			meta:set_int("baz", 42)
			local result = stack:to_table()
			local expected = {
				name = "test",
				count = 101,
				wear = 1337,
				meta = {
					foo = "bar",
					baz = "42",
				}
			}
			assert.same(expected, result)
		end)

		it("is nil for empty stack", function()
			local stack = ItemStack("test 0")
			stack:set_wear(1337)
			local meta = stack:get_meta()
			meta:set_string("foo", "bar")
			meta:set_int("baz", 42)
			assert.is_nil(stack:to_table())
		end)

	end)

	describe("to_string", function()

		it("empty stack", function()
			local stack = ItemStack(nil)
			assert.equals('', stack:to_string())
		end)

		it("empty stack with item name", function()
			local stack = ItemStack("test")
			stack:set_count(0)
			assert.equals('', stack:to_string())
		end)

		it("default stack with item name", function()
			local stack = ItemStack("test")
			assert.equals('test', stack:to_string())
		end)

		it("item name and count", function()
			local stack = ItemStack("test")
			stack:set_count(101)
			assert.equals('test 101', stack:to_string())
		end)

		it("item name, count and wear", function()
			local stack = ItemStack("test")
			stack:set_count(101)
			stack:set_wear(1337)
			assert.equals('test 101 1337', stack:to_string())
		end)

		it("item name, count, wear and meta", function()
			local stack = ItemStack("test")
			stack:set_count(101)
			stack:set_wear(1337)
			local meta = stack:get_meta()
			meta:set_string("foo", "bar")
			assert.equals('test 101 1337 return {["foo"] = "bar"}', stack:to_string())
		end)

		it("default stack with meta", function()
			local stack = ItemStack("test")
			local meta = stack:get_meta()
			meta:set_string("foo", "bar")
			assert.equals('test 1 0 return {["foo"] = "bar"}', stack:to_string())
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

		it("get_definition unknown", function()
			local result = ItemStack("testunknown"):get_definition()
			assert.is_nil(result)
		end)

	end)

	describe("metadata", function()

		local oldconfig = mineunit:config("deprecated")
		after_each(function()
			mineunit:config_set("deprecated", oldconfig)
		end)

		it("get_metadata deprecated", function()
			local stack = ItemStack("test")
			stack:get_meta():set_string("", "test-metadata-value")
			assert.has_error(function()
				stack:get_metadata()
			end)
			mineunit:config_set("deprecated", "ignore")
			local meta = stack:get_metadata()
			assert.is_string(meta)
			assert.equals('test-metadata-value', meta)
		end)

		it("set_metadata deprecated", function()
			local stack = ItemStack("test")
			assert.has_error(function()
				stack:set_metadata("test-metadata-value")
			end)
			mineunit:config_set("deprecated", "ignore")
			local empty = stack:get_metadata()
			assert.is_nil(empty)
			local result = stack:set_metadata("test-metadata-value")
			assert.is_true(result)
			local meta = stack:get_metadata()
			assert.is_string(meta)
			assert.equals('test-metadata-value', meta)
		end)

	end)

end)
