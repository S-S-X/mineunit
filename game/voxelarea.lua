mineunit("common/vector")

local math_huge = math.huge
local vector_new, vector_offset, vector_round = vector.new, vector.offset, vector.round

VoxelArea = {
	MinEdge = vector_new(1, 1, 1),
	MaxEdge = vector_new(0, 0, 0),
	ystride = 0,
	zstride = 0,
	_nx = 0, _ny = 0, _nz = 0,
}

function VoxelArea:new(o)
	setmetatable(o, self)
	self.__index = self
	o.MinEdge = vector_round(o.MinEdge)
	o.MaxEdge = vector_round(o.MaxEdge)
	o._nx = o.MaxEdge.x - o.MinEdge.x + 1
	o._ny = o.MaxEdge.y - o.MinEdge.y + 1
	o._nz = o.MaxEdge.z - o.MinEdge.z + 1
	o.ystride = o._nx
	o.zstride = o._ny * o._nx
	return o
end

function VoxelArea:getExtent()
	return vector_new(self._nx, self._ny, self._nz)
end

function VoxelArea:getVolume()
	return self._nx * self._ny * self._nz
end

function VoxelArea:index(x, y, z)
	local min_edge = self.MinEdge
	return (z - min_edge.z) * self.zstride + (y - min_edge.y) * self.ystride + (x - min_edge.x) + 1
end

function VoxelArea:indexp(p)
	return self:index(p.x, p.y, p.z)
end

function VoxelArea:position(i)
	local zstride, ystride = self.zstride, self.ystride
	local zyx = i - 1
	local yx = zyx % zstride
	local x = zyx % ystride
	local y = (yx - x) / ystride
	local z = (zyx - yx) / zstride
	return vector_offset(self.MinEdge, x, y, z)
end

function VoxelArea:contains(x, y, z)
	local min_edge, max_edge = self.MinEdge, self.MaxEdge
	return x >= min_edge.x and x <= max_edge.x
			and y >= min_edge.y and y <= max_edge.y
			and z >= min_edge.z and z <= max_edge.z
end

function VoxelArea:containsp(p)
	return self:contains(p.x, p.y, p.z)
end

function VoxelArea:containsi(i)
	return i > 0 and i <= self:getVolume()
end

function VoxelArea:iter(minx, miny, minz, maxx, maxy, maxz)
	local zstride = self.zstride
	local ystride = self.ystride
	local i = self:index(minx, miny, minz) - 1
	local prev_line = i + 1
	local prev_sheet = i + 1
	local line_end = self:index(maxx, miny, minz)
	local sheet_end = self:index(maxx, maxy, minz)
	local volume_end = self:index(maxx, maxy, maxz)

	return function()
		i = i + 1
		if i > line_end then
			if i > sheet_end then
				if i > volume_end then
					-- End
					i = nil
				else
					i = prev_sheet + zstride
					line_end = i + (maxx - minx)
					prev_sheet = i
					sheet_end = sheet_end + zstride
				end
			else
				i = prev_line + ystride
				line_end = line_end + ystride
			end
			prev_line = i
		end
		return i
	end
end

function VoxelArea:iterp(minp, maxp)
	return self:iter(minp.x, minp.y, minp.z, maxp.x, maxp.y, maxp.z)
end
