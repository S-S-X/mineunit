-- For self tests package path must be set in a way that makes package loaders search current directory first
package.path = "./?.lua;../?/init.lua;../?.lua;" --.. package.path

describe("Mineunit Player", function()

	require("mineunit")
	mineunit("core")
	mineunit("itemstack")
	mineunit("entity")
	mineunit("player")

	core.register_node(":default:stone", {
		description = "stone",
		buildable_to = false,
		walkable = true,
		drawtype = "nodebox",
		node_box = {
			type = "fixed",
			fixed = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
		},
		collision_box = {
			type = "fixed",
			fixed = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
		},
		selection_box = {
			type = "fixed",
			fixed = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
		},
		nodebox = {}
	})

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

			validate_pointed_thing(pointed_thing, surface_pos)
			return itemstack
		end
	})

	world.set_node({x=2,y=0,z=0}, "default:stone")

	local SX = Player("SX")
	SX:get_inventory():set_stack("main", 1, "check")

	describe(":do_place(...) pointing forward", function()

		it("Crosshair location is correct at center", function()
			SX:do_set_pos_fp({x=0,y=0,z=0})
			SX:do_set_look_xyz("X+")
			validate_pointed_thing = function(pointed_thing, surface_pos)
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
			validate_pointed_thing = function(pointed_thing, surface_pos)
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
			validate_pointed_thing = function(pointed_thing, surface_pos)
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
			validate_pointed_thing = function(pointed_thing, surface_pos)
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
			validate_pointed_thing = function(pointed_thing, surface_pos)
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
			validate_pointed_thing = function(pointed_thing, surface_pos)
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
			validate_pointed_thing = function(pointed_thing, surface_pos)
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
			validate_pointed_thing = function(pointed_thing, surface_pos)
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

end)
