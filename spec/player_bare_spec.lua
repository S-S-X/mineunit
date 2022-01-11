-- For self tests package path must be set in a way that makes package loaders search current directory first
package.path = "./?.lua;../?/init.lua;../?.lua;" --.. package.path

describe("Mineunit Player", function()

	require("mineunit")
	mineunit("itemstack")
	sourcefile("player")

	describe("core.check_player_privs (player)", function()

		-- For some reason engine returns empty string instead of empty table if no privileges missing.
		-- This is really what engine does and it is not mistake in following tests.

		it("Player success no privileges", function()
			local player = Player("p1", {})
			local expected_result = true
			local expected_missing = ""
			local result, missing = core.check_player_privs(player, {})
			assert.equals(expected_result, result)
			assert.same(expected_missing, missing)
		end)

		it("Player fail missing privilege", function()
			local player = Player("p2", {})
			local expected_result = false
			local expected_missing = { "p2" }
			local result, missing = core.check_player_privs(player, { p2 = true })
			assert.equals(expected_result, result)
			assert.same(expected_missing, missing)
		end)

		it("Player success 1 privilege", function()
			local player = Player("p3", { p3 = true })
			local expected_result = true
			local expected_missing = ""
			local result, missing = core.check_player_privs(player, { p3 = true })
			assert.equals(expected_result, result)
			assert.same(expected_missing, missing)
		end)

		it("Player fail 1 privilege", function()
			local player = Player("p4", { p4b = true })
			local expected_result = false
			-- For some reason engine returns empty string if no privileges missing
			local expected_missing = { "p4" }
			local result, missing = core.check_player_privs(player, { p4 = true })
			assert.equals(expected_result, result)
			assert.same(expected_missing, missing)
		end)

		it("Player success 2 privileges", function()
			local player = Player("p5", { p5a = true, p5b = true })
			local expected_result = true
			-- For some reason engine returns empty string if no privileges missing
			local expected_missing = ""
			local result, missing = core.check_player_privs(player, { p5a = true, p5b = true })
			assert.equals(expected_result, result)
			assert.same(expected_missing, missing)
		end)

		it("Player fail 2 privileges", function()
			local player = Player("p6", { p6a = true, p6b = true })
			local expected_result = false
			-- For some reason engine returns empty string if no privileges missing
			local expected_missing = { "p6c", "p6d" }
			local result, missing = core.check_player_privs(player, { p6c = true, p6d = true })
			assert.equals(expected_result, result)
			table.sort(missing)
			assert.same(expected_missing, missing)
		end)

		it("Player success excess player privileges", function()
			local player = Player("p7", { p7a = true, p7b = true })
			local expected_result = true
			-- For some reason engine returns empty string if no privileges missing
			local expected_missing = ""
			local result, missing = core.check_player_privs(player, { p7b = true })
			assert.equals(expected_result, result)
			assert.same(expected_missing, missing)
		end)

		it("Player fail excess required privileges", function()
			local player = Player("p8", { p8a = true, p8b = true })
			local expected_result = false
			-- For some reason engine returns empty string if no privileges missing
			local expected_missing = { "p8d" }
			local result, missing = core.check_player_privs(player, { p8b = true, p8d = true })
			assert.equals(expected_result, result)
			assert.same(expected_missing, missing)
		end)

	end)

end)
