
-- For self tests package path must be set in a way that makes package loaders search current directory first
package.path = "./?.lua;../?/init.lua;../?.lua;" --.. package.path

describe("VoxelManip", function()

	require("mineunit")
	sourcefile("voxelmanip")
	mineunit("core")
	mineunit("common/vector")
	mineunit("world")

	mineunit:set_current_modname("test")
	minetest.register_node("test:node", {})
	minetest.register_node("test:node2", {})

	local vm

	before_each(function()
		world.clear()
		world.layout({
			{vector.new(0, 0, 0), "test:node"},
			{vector.new(20, 0, 0), "test:node"},
			{vector.new(0, 20, 0), "test:node"},
		})
		vm = VoxelManip(vector.new(0, 0, 0), vector.new(20, 0, 0))
		vm:read_from_map(vector.new(0, 0, 0), vector.new(0, 20, 0))
	end)

	it("nodes", function()
		assert.same({name = "test:node", param1 = 0, param2 = 0}, vm:get_node_at(vector.new(0, 0, 0)))
		assert.same({name = "ignore", param1 = 0, param2 = 0}, vm:get_node_at(vector.new(1, 1, 1)))
		assert.same({name = "ignore", param1 = 0, param2 = 0}, vm:get_node_at(vector.new(17, 17, 0)))
		assert.same({name = "ignore", param1 = 0, param2 = 0}, vm:get_node_at(vector.new(100, 100, 100)))
		vm:set_node_at(vector.new(0, 0, 0), {name = "test:node2"})
		vm:set_node_at(vector.new(1, 1, 1), {name = "test:node2"})
		vm:set_node_at(vector.new(17, 17, 0), {name = "test:node2"})
		vm:set_node_at(vector.new(100, 100, 100), {name = "test:node2"})
		assert.same({name = "test:node2", param1 = 0, param2 = 0}, vm:get_node_at(vector.new(0, 0, 0)))
		assert.same({name = "test:node2", param1 = 0, param2 = 0}, vm:get_node_at(vector.new(1, 1, 1)))
		assert.same({name = "ignore", param1 = 0, param2 = 0}, vm:get_node_at(vector.new(17, 17, 0)))
		assert.same({name = "ignore", param1 = 0, param2 = 0}, vm:get_node_at(vector.new(100, 100, 100)))
	end)

	it("get data", function()
		local data = vm:get_data()
		local param1_data = vm:get_light_data()
		local param2_data = vm:get_param2_data()
		local emin, emax = vm:get_emerged_area()
		local i = 1
		for z = emin.z, emax.z do
			for y = emin.y, emax.y do
				for x = emin.x, emax.x do
					local node1 = vm:get_node_at(vector.new(x, y, z))
					local node2 = {
						name = minetest.get_name_from_content_id(data[i]),
						param1 = param1_data[i], param2 = param2_data[i],
					}
					assert.same(node1, node2)
					i = i + 1
				end
			end
		end
	end)

	it("set data", function()
		local data = {}
		local param1_data = {}
		local param2_data = {}
		local content_id = minetest.get_content_id("test:node2")
		local emin, emax = vm:get_emerged_area()
		local volume = (emax.x - emin.x + 1) * (emax.y - emin.y + 1) * (emax.z - emin.z + 1)
		for i = 1, volume do
			data[i] = content_id
			param1_data[i] = 2
			param2_data[i] = 1
		end
		vm:set_data(data)
		vm:set_light_data(param1_data)
		vm:set_param2_data(param2_data)
		assert.same({name = "test:node2", param1 = 2, param2 = 1}, vm:get_node_at(vector.new(0, 0, 0)))
		assert.same({name = "test:node2", param1 = 2, param2 = 1}, vm:get_node_at(vector.new(1, 1, 1)))
		assert.same({name = "ignore", param1 = 0, param2 = 0}, vm:get_node_at(vector.new(17, 17, 0)))
		assert.same({name = "ignore", param1 = 0, param2 = 0}, vm:get_node_at(vector.new(100, 100, 100)))
	end)

	it("write", function()
		vm:set_node_at(vector.new(0, 0, 0), {name = "test:node2"})
		vm:set_node_at(vector.new(1, 1, 1), {name = "test:node2"})
		vm:set_node_at(vector.new(17, 17, 0), {name = "test:node2"})
		vm:set_node_at(vector.new(100, 100, 100), {name = "test:node2"})
		vm:write_to_map()
		assert.same({name = "test:node2", param1 = 0, param2 = 0}, minetest.get_node(vector.new(0, 0, 0)))
		assert.same({name = "test:node2", param1 = 0, param2 = 0}, minetest.get_node(vector.new(1, 1, 1)))
		assert.same({name = "ignore", param1 = 0, param2 = 0}, minetest.get_node(vector.new(17, 17, 0)))
		assert.same({name = "ignore", param1 = 0, param2 = 0}, minetest.get_node(vector.new(100, 100, 100)))
	end)
end)
