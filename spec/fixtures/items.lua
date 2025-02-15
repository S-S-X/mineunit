core.register_node(":chest", {
	description = "chest",
	buildable_to = false,
	walkable = true,
	on_construct = function(pos)
		local meta = core.get_meta(pos)
		local inv = meta:get_inventory()
		inv:set_size("chest", 3)
	end,
})

core.register_node(":stone", {
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

core.register_node(":cobble", {
	description = "cobble",
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

core.register_node(":bridge", {
	description = "bridge",
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

minetest.register_node(":tree", {
	description = "Apple Tree",
	tiles = {"tree_top.png", "tree_top.png", "tree.png"},
	paramtype2 = "facedir",
	is_ground_content = false,
	groups = {tree = 1, choppy = 2, oddly_breakable_by_hand = 1, flammable = 2},
	on_place = minetest.rotate_node
})

minetest.register_node(":wood", {
	description = "Apple Wood Planks",
	paramtype2 = "facedir",
	place_param2 = 0,
	tiles = {"wood.png"},
	is_ground_content = false,
	groups = {choppy = 2, oddly_breakable_by_hand = 2, flammable = 2, wood = 1},
})

minetest.register_node(":bush_stem", {
	description = "Bush Stem",
	drawtype = "plantlike",
	visual_scale = 1.41,
	tiles = {"bush_stem.png"},
	inventory_image = "bush_stem.png",
	wield_image = "bush_stem.png",
	paramtype = "light",
	sunlight_propagates = true,
	groups = {choppy = 2, oddly_breakable_by_hand = 1, flammable = 2},
	selection_box = {
		type = "fixed",
		fixed = {-7 / 16, -0.5, -7 / 16, 7 / 16, 0.5, 7 / 16},
	},
})

minetest.register_craft({
	type = "cooking",
	output = "stone",
	recipe = "cobble",
})

minetest.register_craft({
	output = "wood 4",
	recipe = {
		{"tree"},
	}
})

minetest.register_craft({
	output = "wood",
	recipe = {
		{"bush_stem"},
	}
})

minetest.register_craft({
	type = "fuel",
	recipe = "bush_stem",
	burntime = 7,
})

minetest.register_craft({
	type = "fuel",
	recipe = "group:wood",
	burntime = 7,
})

minetest.register_craft({
	type = "fuel",
	recipe = "group:tree",
	burntime = 30,
})
