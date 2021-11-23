
-- For self tests package path must be set in a way that makes package loaders search current directory first
package.path = "./?.lua;../?/init.lua;../?.lua;" --.. package.path

describe("NodeMetaRef", function()

	require("mineunit")
	sourcefile("itemstack")
	-- itemstack already loads metadata as dependency
	--sourcefile("metadata")
	mineunit("assert")

	core.registered_items = {
		test = { stack_max = 100 }
	}

	describe("inventory", function()

		it("new inventory is empty", function()
			local meta = NodeMetaRef()
			local inv = meta:get_inventory()
			assert.is_true(inv:is_empty("main"))
		end)

		it("inventory:add_item not empty", function()
			local meta = NodeMetaRef()
			local inv = meta:get_inventory()
			inv:set_size("main", 1)
			inv:add_item("main", ItemStack("test 1"))
			assert.is_false(inv:is_empty("main"))
		end)

		it("inventory:set_stack not empty", function()
			local meta = NodeMetaRef()
			local inv = meta:get_inventory()
			inv:set_size("main", 1)
			inv:set_stack("main", 1, ItemStack("test 1"))
			assert.is_false(inv:is_empty("main"))
		end)

		it("inventory:add_item is empty", function()
			local meta = NodeMetaRef()
			local inv = meta:get_inventory()
			inv:set_size("main", 1)
			inv:add_item("main", ItemStack("test 0"))
			assert.is_true(inv:is_empty("main"))
		end)

		it("inventory:set_stack is empty", function()
			local meta = NodeMetaRef()
			local inv = meta:get_inventory()
			inv:set_size("main", 1)
			inv:set_stack("main", 1, ItemStack("test 0"))
			assert.is_true(inv:is_empty("main"))
		end)

	end)

	describe("fields", function()

		it("new instance is empty", function()
			local meta = NodeMetaRef()
			assert.same({}, meta._data)
		end)

		it("set_string string", function()
			local meta = NodeMetaRef()
			meta:set_string("test", "foobar")
			assert.equals("foobar", meta:get("test"))
		end)

		it("set_string empty", function()
			local meta = NodeMetaRef()
			meta:set_string("test", "foobar")
			meta:set_string("test", "")
			assert.is_nil(meta:get("test"))
		end)

		it("set_int integer", function()
			local meta = NodeMetaRef()
			meta:set_int("test", 3)
			assert.equals("3", meta:get("test"))
			assert.equals(3, meta:get_int("test"))
		end)

		it("set_int float is truncated", function()
			local meta = NodeMetaRef()
			meta:set_int("test", 3.6)
			assert.equals("3", meta:get("test"))
			assert.equals(3, meta:get_int("test"))
		end)

		it("get on empty", function()
			local meta = NodeMetaRef()
			assert.is_nil(meta:get("test"))
		end)

		it("get_int on empty", function()
			local meta = NodeMetaRef()
			assert.equals(0, meta:get_int("test"))
		end)

		it("get_string on empty", function()
			local meta = NodeMetaRef()
			assert.equals("", meta:get_string("test"))
		end)

	end)

end)
