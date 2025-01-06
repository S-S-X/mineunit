unused_args = false

-- Exclude regression tests / unit tests
exclude_files = {
	"**/core/**",
	"**/spec/**",
	"**/demo_spec/**",
}

globals = {
	"mineunit", "world",
	"mineunit_path", "fixture", "fixture_path",
	"core", "minetest",
	"vector", "dump","dump2",
	"default",
}

read_globals = {
	-- luassert
	assert = { fields = {
		"is_string", "is_table", "player_or_name", "is_ItemStack", "is_Player"
	}},

	-- Mineunit
	"mineunit_config", "mineunit_conf_defaults", "mineunit_conf_override",
	"NodeTimerRef", "MetaDataRef", "NodeMetaRef", "ObjectRef", "InvRef",

	-- Minetest
	string = {fields = {"split", "trim"}},
	table = {fields = {"copy", "getn"}},
	"PseudoRandom", "ItemStack", "VoxelArea", "VoxelManip", "Settings",
}
