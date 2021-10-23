
-- Add some simple nodes

local function register_default(name)
	minetest.register_node(":default:"..name, {
		description = name.." description",
		tiles = name.."_texture.png",
		buildable_to = false,
		walkable = true,
	})
end

register_default("furnace")
register_default("stone")
register_default("stonebrick")
register_default("sand")
register_default("sandstone")
register_default("sandstonebrick")
register_default("steelblock")
