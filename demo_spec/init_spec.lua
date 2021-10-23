require("mineunit")

mineunit("player")
mineunit("protection")
mineunit("common/after")
mineunit("server")
mineunit("voxelmanip")

fixture("default")
fixture("mesecons")
fixture("digilines")
fixture("pipeworks")

describe("Mod initialization", function()

	-- Create world with 100 x 1 x 3 stone layer and 3 nodes high air layer.
	-- Also add single steel block for demonstration purposes.
	world.layout({
		{{{x=0,y=0,z=-1},{x=99,y=0,z=1}}, "default:stone"},
		{{{x=0,y=1,z=-1},{x=99,y=3,z=1}}, "air"},
		{{x=0,y=1,z=1}, "defaul:steelblock"},
	})

	-- Load current mod executing init.lua
	sourcefile("init")

	-- Execute on mods loaded callbacks to finish loading.
	mineunit:mods_loaded()
	-- Tell mods that 1 minute passed already to execute all weird minetest.after hacks.
	mineunit:execute_globalstep(60)

	local Sam = Player("Sam")

	-- Players join before tests begin
	setup(function()
		mineunit:execute_on_joinplayer(Sam)
	end)

	-- Players leave after tests finished
	teardown(function()
		mineunit:execute_on_leaveplayer(Sam)
	end)

	-- Generate placement test for all registered nodes without not_in_creative_inventory group
	local function placement_test(name, xpos)
        return function()
			Sam:get_inventory():set_stack("main", 1, name)
			Sam:do_place({x=xpos, y=1, z=0})
        end
	end
	local xpos = 0
	for nodename, def in pairs(minetest.registered_nodes) do
		if not (def.groups and def.groups.not_in_creative_inventory) then
			it("wont crash placing "..nodename, placement_test(nodename, xpos))
			xpos = xpos + 1
        end
	end

	it("placed all nodes", function()
		pending("This test might be too simple for potentially complex operation and fails if node is changed")
		local index = 0
		for nodename, def in pairs(minetest.registered_nodes) do
			if not (def.groups and def.groups.not_in_creative_inventory) then
				local node = minetest.get_node({x=index, y=1, z=0})
				assert.equals(node.name, nodename)
				index = index + 1
			end
		end
	end)

	-- Execute globalstep few times just to see if something happens
	it("gloabalstep works", function()
		for _=1,60 do
			mineunit:execute_globalstep(0.42)
		end
	end)

end)
