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
