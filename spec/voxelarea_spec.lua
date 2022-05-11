
-- For self tests package path must be set in a way that makes package loaders search current directory first
package.path = "./?.lua;../?/init.lua;../?.lua;" --.. package.path

describe("VoxelArea", function()

	require("mineunit")
	sourcefile("game/voxelarea")
	mineunit("common/vector")

	local MinEdge = vector.new(-10, -20, -30)
	local MaxEdge = vector.new(6, 7, 8)
	local va = VoxelArea:new{MinEdge = MinEdge, MaxEdge = MaxEdge}

	it("contains", function()
		assert.is_true(va:containsp(MinEdge))
		assert.is_true(va:containsp(MaxEdge))
		assert.is_false(va:containsp(vector.subtract(MinEdge, 1)))
		assert.is_false(va:containsp(vector.add(MaxEdge, 1)))
		assert.is_true(va:containsi(1))
		assert.is_true(va:containsi(2))
		assert.is_false(va:containsi(0))
		assert.is_false(va:containsi(math.huge))
	end)

	it("index-position conversion", function()
		local p = vector.new(5, 6, 7)
		local i = va:indexp(p)
		assert.same(p, va:position(i))
		assert.equal(i, va:indexp(p))
	end)

	it("iteration", function()
		local p1 = vector.new(-3, -2, -1)
		local p2 = vector.new(6, 5, 4)
		local iter = va:iterp(p1, p2)
		local p = vector.new(p1)
		while p.z <= p2.z do
			while p.y <= p2.y do
				while p.x <= p2.x do
					assert.equal(va:indexp(p), iter())
					p.x = p.x + 1
				end
				p.x = p1.x
				p.y = p.y + 1
			end
			p.y = p1.y
			p.z = p.z + 1
		end
		assert.is_nil(iter())
	end)
end)
