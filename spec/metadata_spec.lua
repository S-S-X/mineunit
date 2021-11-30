
-- For self tests package path must be set in a way that makes package loaders search current directory first
package.path = "./?.lua;../?/init.lua;../?.lua;" --.. package.path

describe("NodeMetaRef", function()

	require("mineunit")
	sourcefile("itemstack")
	-- itemstack already loads metadata as dependency
	--sourcefile("metadata")
	mineunit("assert")

	core.registered_items = {
		test = { stack_max = 100 },
		foo = { stack_max = 50 }
	}

	describe("inventory", function()

		it("new inventory is empty", function()
			local meta = NodeMetaRef()
			local inv = meta:get_inventory()
			assert.is_true(inv:is_empty("main"))
		end)

		describe("InvRef:add_item", function()

			it("not empty", function()
				local meta = NodeMetaRef()
				local inv = meta:get_inventory()
				inv:set_size("main", 1)
				inv:add_item("main", ItemStack("test 1"))
				assert.is_false(inv:is_empty("main"))
			end)

			it("is empty", function()
				local meta = NodeMetaRef()
				local inv = meta:get_inventory()
				inv:set_size("main", 1)
				inv:add_item("main", ItemStack("test 0"))
				assert.is_true(inv:is_empty("main"))
			end)

		end)

		describe("InvRef:set_stack", function()

			it("not empty", function()
				local meta = NodeMetaRef()
				local inv = meta:get_inventory()
				inv:set_size("main", 1)
				inv:set_stack("main", 1, ItemStack("test 1"))
				assert.is_false(inv:is_empty("main"))
			end)

			it("is empty", function()
				local meta = NodeMetaRef()
				local inv = meta:get_inventory()
				inv:set_size("main", 1)
				inv:set_stack("main", 1, ItemStack("test 0"))
				assert.is_true(inv:is_empty("main"))
			end)

		end)

		describe("InvRef:set_list", function()

			it("set empty list", function()
				local meta = NodeMetaRef()
				local inv = meta:get_inventory()
				inv:set_size("main", 3)
				inv:set_list("main", {})
				local expected = {
					ItemStack(),
					ItemStack(),
					ItemStack()
				}
				assert.is_true(inv:is_empty("main"))
				assert.same(expected, inv:get_list("main"))
			end)

			it("set ItemStack list beginning", function()
				local meta = NodeMetaRef()
				local inv = meta:get_inventory()
				inv:set_size("main", 3)
				inv:set_list("main", {
					ItemStack("test 1"),
					ItemStack("foo 2"),
				})
				local expected = {
					ItemStack("test 1"),
					ItemStack("foo 2"),
					ItemStack(),
				}
				assert.is_false(inv:is_empty("main"))
				assert.same(expected, inv:get_list("main"))
			end)

			it("set ItemStack list end", function()
				local meta = NodeMetaRef()
				local inv = meta:get_inventory()
				inv:set_size("main", 3)
				inv:set_list("main", {
					ItemStack(),
					ItemStack("test 1"),
					ItemStack("foo 2")
				})
				local expected = {
					ItemStack(),
					ItemStack("test 1"),
					ItemStack("foo 2"),
				}
				assert.is_false(inv:is_empty("main"))
				assert.same(expected, inv:get_list("main"))
			end)

			it("set ItemStack list with stack at beginning", function()
				local meta = NodeMetaRef()
				local inv = meta:get_inventory()
				inv:set_size("main", 3)
				inv:set_stack("main", 1, ItemStack("test 9"))
				inv:set_list("main", {
					ItemStack("test 1"),
					ItemStack("foo 2"),
				})
				local expected = {
					ItemStack("test 1"),
					ItemStack("foo 2"),
					ItemStack()
				}
				assert.is_false(inv:is_empty("main"))
				assert.same(expected, inv:get_list("main"))
			end)

			it("set ItemStack list with stack at end", function()
				local meta = NodeMetaRef()
				local inv = meta:get_inventory()
				inv:set_size("main", 3)
				inv:set_stack("main", 3, ItemStack("test 9"))
				inv:set_list("main", {
					ItemStack("test 1"),
					ItemStack("foo 2"),
				})
				local expected = {
					ItemStack("test 1"),
					ItemStack("foo 2"),
					ItemStack(),
				}
				assert.is_false(inv:is_empty("main"))
				assert.same(expected, inv:get_list("main"))
			end)

			it("set empty ItemStack list", function()
				local meta = NodeMetaRef()
				local inv = meta:get_inventory()
				inv:set_size("main", 3)
				inv:set_list("main", {
					ItemStack("test 0"),
					ItemStack("foo 0"),
				})
				local expected = {
					ItemStack(),
					ItemStack(),
					ItemStack()
				}
				assert.is_true(inv:is_empty("main"))
				assert.same(expected, inv:get_list("main"))
			end)

		end)

		describe("InvRef:contains_item", function()

			it("single stack", function()
				local meta = NodeMetaRef()
				local inv = meta:get_inventory()
				inv:set_size("main", 1)
				inv:set_stack("main", 1, ItemStack("test 1"))
				assert.is_true(inv:contains_item("main", "test 1"))
			end)

			it("single empty", function()
				local meta = NodeMetaRef()
				local inv = meta:get_inventory()
				inv:set_size("main", 1)
				assert.is_false(inv:contains_item("main", "test 1"))
			end)

			it("single middle", function()
				local meta = NodeMetaRef()
				local inv = meta:get_inventory()
				inv:set_size("main", 5)
				inv:set_stack("main", 3, ItemStack("test 1"))
				assert.is_true(inv:contains_item("main", "test 1"))
			end)

			it("multi middle", function()
				local meta = NodeMetaRef()
				local inv = meta:get_inventory()
				inv:set_size("main", 5)
				inv:set_stack("main", 2, ItemStack("foo 1"))
				inv:set_stack("main", 4, ItemStack("test 4"))
				assert.is_true(inv:contains_item("main", "test 4"))
			end)

			it("meta match", function()
				local meta = NodeMetaRef()
				local inv = meta:get_inventory()
				inv:set_size("main", 5)

				local stack1 = ItemStack("test 4")
				stack1:get_meta():set_string("test", "foo")
				inv:set_stack("main", 4, stack1)

				local stack2 = ItemStack("test 4")
				stack2:get_meta():set_string("test", "foo")
				assert.is_true(inv:contains_item("main", stack2, true))
			end)

			it("meta no match", function()
				local meta = NodeMetaRef()
				local inv = meta:get_inventory()
				inv:set_size("main", 5)

				local stack1 = ItemStack("test 4")
				stack1:get_meta():set_string("test", "foo")
				inv:set_stack("main", 4, stack1)

				local stack2 = ItemStack("test 4")
				assert.is_false(inv:contains_item("main", stack2, true))
			end)

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
