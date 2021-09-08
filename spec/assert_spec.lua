
-- For self tests package path must be set in a way that makes package loaders search current directory first
package.path = "./?.lua;../?/init.lua;../?.lua;" --.. package.path

describe("Mineunit assert", function()

	require("mineunit")
	mineunit("player")
	mineunit("itemstack")
	mineunit("metadata")
	mineunit("assert")

	describe("is_Player", function()
		local test_assert = assert.is_Player
		it("does not accept table", function() assert.error(function() assert.is_Player({}) end) end)
		it("does not accept string", function() assert.error(function() assert.is_Player("SX") end) end)
		it("does not accept empty arguments", function() assert.error(function() assert.is_Player() end) end)
		it("does not accept nil", function() assert.error(function() assert.is_Player(nil) end) end)
		it("accepts Player", function() assert.is_Player(Player()) end)
	end)

	describe("is_ItemStack", function()
		local test_assert = assert.is_ItemStack
		it("does not accept table", function() assert.error(function() test_assert({}) end) end)
		it("does not accept string", function() assert.error(function() test_assert("SX") end) end)
		it("does not accept empty arguments", function() assert.error(function() test_assert() end) end)
		it("does not accept nil", function() assert.error(function() test_assert(nil) end) end)
		it("accepts ItemStack", function() test_assert(ItemStack()) end)
	end)

	describe("is_InvRef", function()
		local test_assert = assert.is_InvRef
		it("does not accept table", function() assert.error(function() test_assert({}) end) end)
		it("does not accept string", function() assert.error(function() test_assert("SX") end) end)
		it("does not accept empty arguments", function() assert.error(function() test_assert() end) end)
		it("does not accept nil", function() assert.error(function() test_assert(nil) end) end)
		it("accepts ItemStack", function() test_assert(InvRef()) end)
	end)

	describe("is_MetaDataRef", function()
		local test_assert = assert.is_MetaDataRef
		it("does not accept table", function() assert.error(function() test_assert({}) end) end)
		it("does not accept string", function() assert.error(function() test_assert("SX") end) end)
		it("does not accept empty arguments", function() assert.error(function() test_assert() end) end)
		it("does not accept nil", function() assert.error(function() test_assert(nil) end) end)
		it("does not accept InvRef", function() assert.error(function() test_assert(InvRef()) end) end)
		it("accepts ItemStack", function() test_assert(MetaDataRef()) end)
	end)

	describe("is_NodeMetaRef", function()
		local test_assert = assert.is_NodeMetaRef
		it("does not accept table", function() assert.error(function() test_assert({}) end) end)
		it("does not accept string", function() assert.error(function() test_assert("SX") end) end)
		it("does not accept empty arguments", function() assert.error(function() test_assert() end) end)
		it("does not accept nil", function() assert.error(function() test_assert(nil) end) end)
		it("does not accept InvRef", function() assert.error(function() test_assert(InvRef()) end) end)
		it("accepts ItemStack", function() test_assert(NodeMetaRef()) end)
	end)

	describe("type override", function()

		it("returns Player as userdata", function() assert.equals("userdata", type(Player())) end)
		it("returns ItemStack as userdata", function() assert.equals("userdata", type(ItemStack())) end)
		it("returns InvRef as userdata", function() assert.equals("userdata", type(InvRef())) end)
		it("returns InvList as table", function()
			local inv = InvRef()
			inv:set_size("mylist", 1)
			assert.equals("table", type(inv:get_list("mylist")))
		end)

	end)

end)
