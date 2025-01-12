-- For self tests package path must be set in a way that makes package loaders search current directory first
package.path = "./?.lua;../?/init.lua;../?.lua;" --.. package.path

describe("Mineunit Player", function()

	require("mineunit")
	mineunit:config_set("silence_global_export_overrides", true)
	sourcefile("core")
	sourcefile("itemstack")
	sourcefile("entity")
	sourcefile("player")
	fixture("items")

	local validate_pointed_thing = function() error() end
	core.register_craftitem(":check", {
		description = "check",
		on_place = function(itemstack, placer, pointed_thing)
			assert.is_ItemStack(itemstack)
			assert.is_player(placer)
			assert.is_hashed(pointed_thing)
			assert.equals(pointed_thing.type, "node")
			assert.not_nil(pointed_thing.above)
			assert.not_nil(pointed_thing.under)

			local surface_pos = minetest.pointed_thing_to_face_pos(placer, pointed_thing)
			surface_pos = vector.subtract(surface_pos, pointed_thing.above)

			validate_pointed_thing(pointed_thing, surface_pos, "on_place")
			return itemstack
		end,
		on_secondary_use = function(itemstack, user, pointed_thing)
			-- TODO: Implement on_secondary_use and add basic tests for it
			pending("on_secondary_use not fully implemented for Player")
			assert.is_ItemStack(itemstack)
			assert.is_player(user)
			assert.is_hashed(pointed_thing)
			assert.not_equals(pointed_thing.type, "node")
			assert.not_nil(pointed_thing.above)
			assert.not_nil(pointed_thing.under)

			local surface_pos = minetest.pointed_thing_to_face_pos(user, pointed_thing)
			surface_pos = vector.subtract(surface_pos, pointed_thing.above)

			validate_pointed_thing(pointed_thing, surface_pos, "on_secondary_use")
			return itemstack
		end,
		on_use = function(itemstack, user, pointed_thing)
			assert.is_ItemStack(itemstack)
			assert.is_player(user)
			assert.is_hashed(pointed_thing)
			assert.equals(pointed_thing.type, "node")
			assert.not_nil(pointed_thing.above)
			assert.not_nil(pointed_thing.under)

			local surface_pos = minetest.pointed_thing_to_face_pos(user, pointed_thing)
			surface_pos = vector.subtract(surface_pos, pointed_thing.above)

			validate_pointed_thing(pointed_thing, surface_pos, "on_use")
			return itemstack
		end,
	})

	world.set_node({x=2,y=0,z=0}, "stone")

	local SX = Player("SX")
	SX:get_inventory():set_stack("main", 1, "check")

	describe(":do_place(...) pointing forward", function()

		it("Crosshair location is correct at center", function()
			SX:do_set_pos_fp({x=0,y=0,z=0})
			SX:do_set_look_xyz("X+")
			validate_pointed_thing = function(pointed_thing, surface_pos, callback)
				assert.equals("on_place", callback)
				assert.is_hashed(pointed_thing)
				assert.same({type="node",above={x=1,y=0,z=0},under={x=2,y=0,z=0}}, pointed_thing)

				assert.is_hashed(surface_pos)
				assert.close_enough(0.50, surface_pos, "surface_pos.x")
				assert.close_enough(0.00, surface_pos, "surface_pos.y")
				assert.close_enough(0.00, surface_pos, "surface_pos.z")
			end
			SX:do_place({x=1,y=0,z=0})
		end)

		it("Crosshair location is correct at Y+ edge", function()
			SX:do_set_pos_fp({x=0,y=0.25,z=0})
			SX:do_set_look_xyz("X+")
			validate_pointed_thing = function(pointed_thing, surface_pos, callback)
				assert.equals("on_place", callback)
				assert.is_hashed(pointed_thing)
				assert.same({type="node",above={x=1,y=0,z=0},under={x=2,y=0,z=0}}, pointed_thing)

				assert.is_hashed(surface_pos)
				assert.close_enough(0.50, surface_pos, "surface_pos.x")
				assert.close_enough(0.25, surface_pos, "surface_pos.y")
				assert.close_enough(0.00, surface_pos, "surface_pos.z")
			end
			SX:do_place({x=1,y=0,z=0})
		end)

		it("Crosshair location is correct at Z- edge", function()
			SX:do_set_pos_fp({x=0,y=0,z=-0.5})
			SX:do_set_look_xyz("X+")
			validate_pointed_thing = function(pointed_thing, surface_pos, callback)
				assert.equals("on_place", callback)
				assert.is_hashed(pointed_thing)
				assert.same({type="node",above={x=1,y=0,z=0},under={x=2,y=0,z=0}}, pointed_thing)

				assert.is_hashed(surface_pos)
				assert.close_enough( 0.5, surface_pos, "surface_pos.x")
				assert.close_enough( 0.00, surface_pos, "surface_pos.y")
				assert.close_enough(-0.5, surface_pos, "surface_pos.z")
			end
			SX:do_place({x=1,y=0,z=0})
		end)

		it("Crosshair location is correct at Y- Z+ corner", function()
			SX:do_set_pos_fp({x=0,y=-0.49,z=0.49})
			SX:do_set_look_xyz("X+")
			validate_pointed_thing = function(pointed_thing, surface_pos, callback)
				assert.equals("on_place", callback)
				assert.is_hashed(pointed_thing)
				assert.same({type="node",above={x=1,y=0,z=0},under={x=2,y=0,z=0}}, pointed_thing)

				assert.is_hashed(surface_pos)
				assert.close_enough( 0.50, surface_pos, "surface_pos.x")
				assert.close_enough(-0.49, surface_pos, "surface_pos.y")
				assert.close_enough( 0.49, surface_pos, "surface_pos.z")
			end
			SX:do_place({x=1,y=0,z=0})
		end)

	end)

	describe(":do_place(...) pointing downwards", function()

		it("Crosshair location is correct at center", function()
			SX:do_set_pos_fp({x=2,y=3,z=0})
			SX:do_set_look_xyz("Y-")
			validate_pointed_thing = function(pointed_thing, surface_pos, callback)
				assert.equals("on_place", callback)
				assert.is_hashed(pointed_thing)
				assert.same({type="node",above={x=2,y=1,z=0},under={x=2,y=0,z=0}}, pointed_thing)

				assert.is_hashed(surface_pos)
				assert.close_enough( 0.00, surface_pos, "surface_pos.x")
				assert.close_enough(-0.50, surface_pos, "surface_pos.y")
				assert.close_enough( 0.00, surface_pos, "surface_pos.z")
			end
			SX:do_place({x=2,y=1,z=0})
		end)

		it("Crosshair location is correct at X+ edge", function()
			SX:do_set_pos_fp({x=2+0.4,y=3,z=0})
			SX:do_set_look_xyz("Y-")
			validate_pointed_thing = function(pointed_thing, surface_pos, callback)
				assert.equals("on_place", callback)
				assert.is_hashed(pointed_thing)
				assert.same({type="node",above={x=2,y=1,z=0},under={x=2,y=0,z=0}}, pointed_thing)

				assert.is_hashed(surface_pos)
				assert.close_enough( 0.40, surface_pos, "surface_pos.x")
				assert.close_enough(-0.50, surface_pos, "surface_pos.y")
				assert.close_enough( 0.00, surface_pos, "surface_pos.z")
			end
			SX:do_place({x=2,y=1,z=0})
		end)

		it("Crosshair location is correct at Z- edge", function()
			SX:do_set_pos_fp({x=2,y=3,z=-0.5})
			SX:do_set_look_xyz("Y-")
			validate_pointed_thing = function(pointed_thing, surface_pos, callback)
				assert.equals("on_place", callback)
				assert.is_hashed(pointed_thing)
				assert.same({type="node",above={x=2,y=1,z=0},under={x=2,y=0,z=0}}, pointed_thing)

				assert.is_hashed(surface_pos)
				assert.close_enough( 0.00, surface_pos, "surface_pos.x")
				assert.close_enough(-0.50, surface_pos, "surface_pos.y")
				assert.close_enough(-0.50, surface_pos, "surface_pos.z")
			end
			SX:do_place({x=2,y=1,z=0})
		end)

		it("Crosshair location is correct at X- Z+ corner", function()
			SX:do_set_pos_fp({x=2-0.49,y=3,z=0.49})
			SX:do_set_look_xyz("Y-")
			validate_pointed_thing = function(pointed_thing, surface_pos, callback)
				assert.equals("on_place", callback)
				assert.is_hashed(pointed_thing)
				assert.same({type="node",above={x=2,y=1,z=0},under={x=2,y=0,z=0}}, pointed_thing)

				assert.is_hashed(surface_pos)
				assert.close_enough(-0.49, surface_pos, "surface_pos.x")
				assert.close_enough(-0.50, surface_pos, "surface_pos.y")
				assert.close_enough( 0.49, surface_pos, "surface_pos.z")
			end
			SX:do_place({x=2,y=1,z=0})
		end)

	end)

	describe(":do_use(...) pointing forward", function()

		it("Crosshair location is correct at center", function()
			SX:do_set_pos_fp({x=0,y=0,z=0})
			SX:do_set_look_xyz("X+")
			validate_pointed_thing = function(pointed_thing, surface_pos, callback)
				assert.equals("on_use", callback)
				assert.is_hashed(pointed_thing)
				assert.same({type="node",above={x=1,y=0,z=0},under={x=2,y=0,z=0}}, pointed_thing)

				assert.is_hashed(surface_pos)
				assert.close_enough(0.50, surface_pos, "surface_pos.x")
				assert.close_enough(0.00, surface_pos, "surface_pos.y")
				assert.close_enough(0.00, surface_pos, "surface_pos.z")
			end
			SX:do_use({x=1,y=0,z=0})
		end)

		it("Crosshair location is correct at Y+ edge", function()
			SX:do_set_pos_fp({x=0,y=0.25,z=0})
			SX:do_set_look_xyz("X+")
			validate_pointed_thing = function(pointed_thing, surface_pos, callback)
				assert.equals("on_use", callback)
				assert.is_hashed(pointed_thing)
				assert.same({type="node",above={x=1,y=0,z=0},under={x=2,y=0,z=0}}, pointed_thing)

				assert.is_hashed(surface_pos)
				assert.close_enough(0.50, surface_pos, "surface_pos.x")
				assert.close_enough(0.25, surface_pos, "surface_pos.y")
				assert.close_enough(0.00, surface_pos, "surface_pos.z")
			end
			SX:do_use({x=1,y=0,z=0})
		end)

		it("Crosshair location is correct at Z- edge", function()
			SX:do_set_pos_fp({x=0,y=0,z=-0.5})
			SX:do_set_look_xyz("X+")
			validate_pointed_thing = function(pointed_thing, surface_pos, callback)
				assert.equals("on_use", callback)
				assert.is_hashed(pointed_thing)
				assert.same({type="node",above={x=1,y=0,z=0},under={x=2,y=0,z=0}}, pointed_thing)

				assert.is_hashed(surface_pos)
				assert.close_enough( 0.5, surface_pos, "surface_pos.x")
				assert.close_enough( 0.00, surface_pos, "surface_pos.y")
				assert.close_enough(-0.5, surface_pos, "surface_pos.z")
			end
			SX:do_use({x=1,y=0,z=0})
		end)

		it("Crosshair location is correct at Y- Z+ corner", function()
			SX:do_set_pos_fp({x=0,y=-0.49,z=0.49})
			SX:do_set_look_xyz("X+")
			validate_pointed_thing = function(pointed_thing, surface_pos, callback)
				assert.equals("on_use", callback)
				assert.is_hashed(pointed_thing)
				assert.same({type="node",above={x=1,y=0,z=0},under={x=2,y=0,z=0}}, pointed_thing)

				assert.is_hashed(surface_pos)
				assert.close_enough( 0.50, surface_pos, "surface_pos.x")
				assert.close_enough(-0.49, surface_pos, "surface_pos.y")
				assert.close_enough( 0.49, surface_pos, "surface_pos.z")
			end
			SX:do_use({x=1,y=0,z=0})
		end)

	end)

	describe(":do_use(...) with raycast", function()

		it("Crosshair location is correct at center", function()
			SX:do_set_pos_fp({x=0,y=0,z=0})
			SX:do_set_look_xyz("X+")
			validate_pointed_thing = function(pointed_thing, surface_pos, callback)
				assert.equals("on_use", callback)
				assert.is_hashed(pointed_thing)
				assert.same({type="node",above={x=1,y=0,z=0},under={x=2,y=0,z=0}}, pointed_thing)

				assert.is_hashed(surface_pos)
				assert.close_enough(0.50, surface_pos, "surface_pos.x")
				assert.close_enough(0.00, surface_pos, "surface_pos.y")
				assert.close_enough(0.00, surface_pos, "surface_pos.z")
			end
			SX:do_use()
		end)

		it("Crosshair location is correct at Y+ edge", function()
			SX:do_set_pos_fp({x=0,y=0.25,z=0})
			SX:do_set_look_xyz("X+")
			validate_pointed_thing = function(pointed_thing, surface_pos, callback)
				assert.equals("on_use", callback)
				assert.is_hashed(pointed_thing)
				assert.same({type="node",above={x=1,y=0,z=0},under={x=2,y=0,z=0}}, pointed_thing)

				assert.is_hashed(surface_pos)
				assert.close_enough(0.50, surface_pos, "surface_pos.x")
				assert.close_enough(0.25, surface_pos, "surface_pos.y")
				assert.close_enough(0.00, surface_pos, "surface_pos.z")
			end
			SX:do_use()
		end)

		it("Crosshair location is correct at Z- edge", function()
			SX:do_set_pos_fp({x=0,y=0,z=-0.5})
			SX:do_set_look_xyz("X+")
			validate_pointed_thing = function(pointed_thing, surface_pos, callback)
				assert.equals("on_use", callback)
				assert.is_hashed(pointed_thing)
				assert.same({type="node",above={x=1,y=0,z=0},under={x=2,y=0,z=0}}, pointed_thing)

				assert.is_hashed(surface_pos)
				assert.close_enough( 0.5, surface_pos, "surface_pos.x")
				assert.close_enough( 0.00, surface_pos, "surface_pos.y")
				assert.close_enough(-0.5, surface_pos, "surface_pos.z")
			end
			SX:do_use()
		end)

		it("Crosshair location is correct at Y- Z+ corner", function()
			SX:do_set_pos_fp({x=0,y=-0.49,z=0.49})
			SX:do_set_look_xyz("X+")
			validate_pointed_thing = function(pointed_thing, surface_pos, callback)
				assert.equals("on_use", callback)
				assert.is_hashed(pointed_thing)
				assert.same({type="node",above={x=1,y=0,z=0},under={x=2,y=0,z=0}}, pointed_thing)

				assert.is_hashed(surface_pos)
				assert.close_enough( 0.50, surface_pos, "surface_pos.x")
				assert.close_enough(-0.49, surface_pos, "surface_pos.y")
				assert.close_enough( 0.49, surface_pos, "surface_pos.z")
			end
			SX:do_use()
		end)

	end)

	describe(":do_place_from_above(...)", function()

		it("has correct crosshair and pointed_thing", function()
			validate_pointed_thing = function(pointed_thing, surface_pos, callback)
				assert.equals("on_place", callback)
				assert.is_hashed(pointed_thing)
				assert.same({type="node",above={x=2,y=1,z=0},under={x=2,y=0,z=0}}, pointed_thing)
				assert.nodename("stone", pointed_thing.under)

				assert.is_hashed(surface_pos)
				assert.close_enough( 0.0, surface_pos, "surface_pos.x")
				assert.close_enough(-0.5, surface_pos, "surface_pos.y")
				assert.close_enough( 0.0, surface_pos, "surface_pos.z")
			end
			SX:do_place_from_above({x=2,y=0,z=0})
		end)

	end)

	describe(":do_use_from_above(...)", function()

		it("has correct crosshair and pointed_thing", function()
			validate_pointed_thing = function(pointed_thing, surface_pos, callback)
				assert.equals("on_use", callback)
				assert.is_hashed(pointed_thing)
				assert.same({type="node",above={x=2,y=1,z=0},under={x=2,y=0,z=0}}, pointed_thing)
				assert.nodename("stone", pointed_thing.under)

				assert.is_hashed(surface_pos)
				assert.close_enough( 0.0, surface_pos, "surface_pos.x")
				assert.close_enough(-0.5, surface_pos, "surface_pos.y")
				assert.close_enough( 0.0, surface_pos, "surface_pos.z")
			end
			SX:do_use_from_above({x=2,y=0,z=0})
		end)

	end)

	describe(":do_metadata_inventory_put(...)", function()

		setup(function()
			world.place_node({x=0,y=1,z=0}, "chest")
			local inv = SX:get_inventory()
			inv:set_stack("main", 1, "stone 33")
			inv:set_stack("main", 2, "stone 42")
			inv:set_stack("main", 3, "stone 88")
		end)

		it("works without source index", function()
			SX:do_metadata_inventory_put({x=0,y=1,z=0}, "chest", 1)
			local expected = InvRef()
			expected:set_size("chest", 3)
			expected:set_stack("chest", 1, ItemStack("stone 33"))
			local nodeinv = core.get_meta({x=0,y=1,z=0}):get_inventory()
			assert.same(expected:get_list("chest"), nodeinv:get_list("chest"))
		end)

		it("works with source index", function()
			SX:do_metadata_inventory_put({x=0,y=1,z=0}, "chest", 2, 2)
			local expected = InvRef()
			expected:set_size("chest", 3)
			expected:set_stack("chest", 1, ItemStack("stone 33"))
			expected:set_stack("chest", 2, ItemStack("stone 42"))
			local nodeinv = core.get_meta({x=0,y=1,z=0}):get_inventory()
			assert.same(expected:get_list("chest"), nodeinv:get_list("chest"))
		end)

		it("works with ItemStack", function()
			SX:do_metadata_inventory_put({x=0,y=1,z=0}, "chest", 3, ItemStack("stone 96"))
			local expected = InvRef()
			expected:set_size("chest", 3)
			expected:set_stack("chest", 1, ItemStack("stone 33"))
			expected:set_stack("chest", 2, ItemStack("stone 42"))
			expected:set_stack("chest", 3, ItemStack("stone 96"))
			local nodeinv = core.get_meta({x=0,y=1,z=0}):get_inventory()
			assert.same(expected:get_list("chest"), nodeinv:get_list("chest"))
		end)

	end)

end)

describe("Core function", function()

	require("mineunit")
	mineunit:config_set("silence_global_export_overrides", true)
	sourcefile("core")
	sourcefile("itemstack")
	sourcefile("entity")
	sourcefile("player")

	core.register_craftitem(":test", { description = "test" })

	describe("core.check_player_privs (engine)", function()

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

	describe("core.create_detached_inventory", function()

		it("fails on missing name", function()
			assert.error(function()
				core.create_detached_inventory()
			end)
		end)

		it("creates new inventory", function()
			local inv1 = core.create_detached_inventory("new", nil, nil)
			assert.is_InvRef(inv1)
			local inv2 = core.create_detached_inventory("new", nil, nil)
			assert.is_InvRef(inv2)
			assert.not_equals(inv1, inv2)
		end)

	end)

	describe("core.get_inventory (detached)", function()

		setup(function()
			local inv = core.create_detached_inventory("testinv", nil, nil)
			assert.is_InvRef(inv)
			inv:set_size("list1", 3)
			inv:set_stack("list1", 2, "test")
			assert.has_item(inv, "list1", 2, "test")
		end)

		it("fails on missing name", function()
			assert.error(function()
				core.get_inventory({ type = "detached" })
			end)
		end)

		it("handles empty name", function()
			local inv = core.get_inventory({ type = "detached", name = "" })
			assert.is_nil(inv)
		end)

		it("returns inventory", function()
			local inv = core.get_inventory({ type = "detached", name = "testinv" })
			assert.is_InvRef(inv)
			assert.has_item(inv, "test")
		end)

	end)

	describe("core.get_inventory (player)", function()

		it("fails on missing name", function()
			assert.error(function()
				core.get_inventory({ type = "player" })
			end)
		end)

		it("handles empty name", function()
			local inv = core.get_inventory({ type = "player", name = "" })
			assert.is_nil(inv)
		end)

		it("handles noexistent inventory", function()
			local inv = core.get_inventory({ type = "player", name = "doesntexist" })
			assert.is_nil(inv)
		end)

		it("returns inventory", function()
			local player = Player("Sam")
			player:set_wielded_item("test")
			local inv = core.get_inventory({ type = "player", name = "Sam" })
			assert.is_InvRef(inv)
			assert.has_item(inv, "test")
		end)

	end)

	describe("core.remove_detached_inventory", function()

		it("fails on missing name", function()
			assert.error(function()
				core.remove_detached_inventory()
			end)
		end)

		it("fails on nil name", function()
			assert.error(function()
				core.remove_detached_inventory(nil)
			end)
		end)

		it("handles empty name", function()
			local inv = core.remove_detached_inventory("")
			assert.is_false(inv)
		end)

		it("wont remove player inventory", function()
			local player = Player("Sam")
			player:set_wielded_item("test")
			local inv = core.remove_detached_inventory("Sam")
			assert.is_false(inv)
			assert.has_item(player, "test")
		end)

		it("handles noexistent inventory", function()
			local inv = core.remove_detached_inventory("doesntexist")
			assert.is_false(inv)
		end)

	end)

	describe("Formspec system", function()

		mineunit("formspec")

		local player = Player("p9", {})
		before_each(function()
			mineunit:execute_on_joinplayer(player)
		end)

		after_each(function()
			mineunit:execute_on_leaveplayer(player)
		end)

		it("should show formspecs to the player", function()
			core.show_formspec("p9", "fs1", "field[foo;bar;baz]")
			local form = mineunit:get_player_formspec("p9")
			assert.is_Form(form)
			assert.equals("fs1", form:name())
			assert.equals("field[foo;bar;baz]", form:text())
		end)

		it("should not hide formspecs when the form name does not match", function()
			core.show_formspec("p9", "fs1", "field[foo;bar;baz]")
			core.close_formspec("p9", "fs2")
			local form = mineunit:get_player_formspec("p9")
			assert.is_Form(form)
			assert.equals("fs1", form:name())
			assert.equals("field[foo;bar;baz]", form:text())
		end)

		it("should close formspecs when the form name matches", function()
			core.show_formspec("p9", "fs1", "field[foo;bar;baz]")
			core.close_formspec("p9", "fs1")
			assert.is_nil(mineunit:get_player_formspec("p9"))
		end)

		it("should close formspecs when the empty form name is passed", function()
			core.show_formspec("p9", "fs1", "field[foo;bar;baz]")
			core.close_formspec("p9", "")
			assert.is_nil(mineunit:get_player_formspec("p9"))
		end)

		it("should call callbacks correctly", function()
			local count = 0
			local realfields = { quit = "true" }
			core.register_on_player_receive_fields(function(playername, formname, fields)
				if formname == "fs1" then
					count = 10
				end
			end)
			core.register_on_player_receive_fields(function(playername, formname, fields)
				assert.same(realfields, fields)
				count = 1
				return true
			end)
			core.show_formspec("p9", "fs1", "field[foo;bar;baz]")
			local form = mineunit:get_player_formspec("p9")
			form:send("p9", realfields)
			assert.equal(1, count)
		end)

	end)

end)
