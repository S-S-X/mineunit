unused_args = false

-- Exclude regression tests / unit tests
exclude_files = {
	"./core/**",
	"./spec/**",
	"./demo_spec/**",
	"./common/**",
	"./game/**",
}

globals = {
	-- Globals
	"type",

	-- Mineunit
	"mineunit", "world",
	"mineunit_path", "fixture", "fixture_path", "sourcefile",

	-- Engine
	"INIT", "PLATFORM", "DIR_DELIM",
	"core", "minetest",
	"vector", "dump","dump2",

	-- MTG
	"default",
}

read_globals = {
	-- luassert
	assert = { fields = {
		"is_string", "is_table", "player_or_name", "is_ItemStack", "is_Player",
		"is_true", "is_itemstring", "is_itemname", "is_number", "is_integer",
		"is_nil", "not_nil",
		"is_indexed", "is_hashed", "in_array",
	}},

	-- Mineunit
	"mineunit_config", "mineunit_conf_defaults", "mineunit_conf_override",
	"NodeTimerRef", "MetaDataRef", "NodeMetaRef", "ObjectRef", "InvRef",

	-- Minetest
	string = {fields = {"split", "trim"}},
	table = {fields = {"copy", "getn", "indexof", "insert_all", "key_value_swap", "shuffle"}},
	math = {fields = {"hypot", "sign", "factorial"}},
	"PseudoRandom", "ItemStack", "VoxelArea", "VoxelManip", "Settings",
}

for i = 1, #read_globals.assert.fields do
	local s = read_globals.assert.fields[i]
	if s:sub(1,3) == "is_" then
		table.insert(read_globals.assert.fields, "not_" .. s:sub(4))
	end
end