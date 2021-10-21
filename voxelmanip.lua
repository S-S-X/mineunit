local VoxelManip = {}

function blockpos(p)
	return math.floor(p / 16)
end

function nodepos_min(p)
	return p * 16
end

function nodepos_max(p)
	return p * 16 + 15
end

local function mapblock_area(pos)
	local bx, by, bz = blockpos(pos.x), blockpos(pos.y), blockpos(pos.z)
	return 
		{ x = nodepos_min(bx), y = nodepos_min(by), z = nodepos_min(bz) },
		{ x = nodepos_max(bx), y = nodepos_max(by), z = nodepos_max(bz) }
end

--
-- VoxelManip public API
--

function VoxelManip:read_from_map(pos1, pos2)
	return mapblock_area(pos1)[1], mapblock_area(pos2)[2]
end

mineunit.export_object(VoxelManip, {
	name = "VoxelManip",
	constructor = function(self)
		local obj = {}
		setmetatable(obj, VoxelManip)
		return obj
	end,
})

local VoxelArea = {}

--* `getExtent()`: returns a 3D vector containing the size of the area formed by `MinEdge` and `MaxEdge`.
function VoxelArea:getExtent()
end

--* `getVolume()`: returns the volume of the area formed by `MinEdge` and `MaxEdge`.
function VoxelArea:getVolume()
end

--* `index(x, y, z)`: returns the index of an absolute position in a flat array starting at `1`.
--    * `x`, `y` and `z` must be integers to avoid an incorrect index result.
--    * The position (x, y, z) is not checked for being inside the area volume,
--      being outside can cause an incorrect index result.
--    * Useful for things like `VoxelManip`, raw Schematic specifiers, `PerlinNoiseMap:get2d`/`3dMap`, and so on.
function VoxelArea:index(x, y, z)
end

--* `indexp(p)`: same functionality as `index(x, y, z)` but takes a vector.
--    * As with `index(x, y, z)`, the components of `p` must be integers, and `p`
--      is not checked for being inside the area volume.
function VoxelArea:indexp(p)
end

--* `position(i)`: returns the absolute position vector corresponding to index `i`.
function VoxelArea:position(i)
end

--* `contains(x, y, z)`: check if (`x`,`y`,`z`) is inside area formed by `MinEdge` and `MaxEdge`.
function VoxelArea:contains(x, y, z)
end

--* `containsp(p)`: same as above, except takes a vector
function VoxelArea:containsp(p)
end

--* `containsi(i)`: same as above, except takes an index `i`
function VoxelArea:containsi(i)
end

--* `iter(minx, miny, minz, maxx, maxy, maxz)`: returns an iterator that returns indices.
--    * from (`minx`,`miny`,`minz`) to (`maxx`,`maxy`,`maxz`) in the order of `[z [y [x]]]`.
function VoxelArea:iter(minx, miny, minz, maxx, maxy, maxz)
end

--* `iterp(minp, maxp)`: same as above, except takes a vector
function VoxelArea:iterp(minp, maxp)
end

--A helper class for voxel areas.
--It can be created via `VoxelArea:new{MinEdge = pmin, MaxEdge = pmax}`.
--The coordinates are *inclusive*, like most other things in Minetest.
function VoxelArea:new(bounds)
	local obj = {}
	assert(type(bounds) == "table", "VoxelArea: requires table as argument. Argument type was "..type(bounds))
	obj._minp = bounds.MinEdge
	assert(type(obj._minp) == "table", "VoxelArea: MinEdge coordinates required, type was "..type(obj._minp))
	obj._maxp = bounds.MaxEdge
	assert(type(obj._maxp) == "table", "VoxelArea: MaxEdge coordinates required, type was "..type(obj._maxp))
	setmetatable(obj, VoxelArea)
	return obj
end

mineunit.export_object(VoxelArea, {
	name = "VoxelArea",
	constructor = function(self, minedge, maxedge)
		error("Use VoxelArea:new to create new VoxelArea instance")
	end,
})
