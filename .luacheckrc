unused_args = false

max_cyclomatic_complexity = 15

-- Exclude regression tests / unit tests
exclude_files = {
	"./core/**",
	"./common/**",
	"./game/**",
	"./.**/**"
}

local function Writable(what)
	local result = {}
	local rw = { read_only = false, other_fields = true }
	for name, fields in pairs(what) do
		result[name] = { fields = {} }
		for _,fieldname in ipairs(fields) do result[name].fields[fieldname] = rw end
	end
	return result
end

-- Tests and other sources
files["./spec/**"].std = "+busted"
files["./demo_spec/**"].std = "+busted"
files["./jit-p.lua"].ignore = { "561" }

-- Mineunit source files
files["./assert.lua"].globals = { "type" }
files["./assert.lua"].read_globals = Writable{
	mineunit = {
		"debughooks",
	},
}
files["./init.lua"].globals = { "mineunit", "fixture", "fixture_path", "sourcefile", }
files["./config.lua"].read_globals = Writable{
	mineunit = {
		"_config",
		"config",
		"config_set",
	},
}
files["./globals.lua"].globals = { "INIT", "PLATFORM", "DIR_DELIM" }
files["./globals.lua"].read_globals = Writable{
	mineunit = {
		"utils",
		"set_timeofday",
	},
}
files["./settings.lua"].read_globals = Writable{ mineunit = { "apply_default_settings" } }
files["./auth.lua"].read_globals = Writable{ mineunit = { "create_auth" } }
files["./craft.lua"].read_globals = Writable{
	mineunit = { "CraftManager" },
	core = {
		"get_all_craft_recipes",
		"register_craft",
		"clear_craft",
		"get_craft_result",
	}
}
files["./player.lua"].read_globals = Writable{
	mineunit = {
		"get_player_formspec",
		"get_players",
	}
}
files["./entity.lua"].read_globals = Writable{ mineunit = { "get_entities" } }
files["./protection.lua"].read_globals = Writable{
	mineunit = { "protect" },
	core = {
		"is_protected",
		"record_protection_violation",
	}
}
files["./print.lua"].globals = { "dump" }
files["./print.lua"].read_globals = Writable{
	mineunit = {
		"format",
		"prepend_print",
		"prepend_flush",
		"debug",
		"info",
		"warning",
		"error",
		"print",
		"debugf",
		"infof",
		"warningf",
		"errorf",
		"printf",
	}
}
files["./server.lua"].read_globals = Writable{
	mineunit = {
		"destroy_nodetimer",
		"execute_entitystep",
		"execute_globalstep",
		"execute_shutdown",
		"execute_on_joinplayer",
		"execute_on_leaveplayer",
		"execute_on_chat_message",
		"execute_on_player_receive_fields",
		"execute_modchannel_message",
		"execute_modchannel_signal",
	}
}
files["./metadata.lua"].read_globals = Writable{
	mineunit = {
		"get_InvRef_data",
		"clear_InvRef",
	}
}
files["./http.lua"].read_globals = Writable{
	mineunit = { "http_server" },
	core = { "request_http_api" },
}
files["./formspec.lua"].read_globals = Writable{
	mineunit = {
		"Form",
		"send_formspec_fields",
		"set_formspec_fields",
		"set_formspec_field",
	}
}
files["./fs.lua"].read_globals = Writable{
	mineunit = {
		"fs_reset",
		"fs_copy",
		"fs_getfile",
		"fs_raw",
	},
	core = {
		"mkdir",
		"get_dir_list",
		"safe_file_write",
	}
}
files["./core.lua"].read_globals = Writable{
	core = {
		"send_join_message",
		"send_leave_message",
	}
}
files["./voxelmanip.lua"].read_globals = Writable{
	world = { "nodes" },
	core = { "get_voxel_manip" },
}

globals = {
	-- FIXME: MTG
	"default",
}

read_globals = {
	-- luassert
	assert = { fields = {
		"string", "table", "player_or_name", "ItemStack", "Player", "coordinate", --"Form",
		"is_string", "is_table", "is_player_or_name", "is_ItemStack", "is_Player", "is_coordinate", --"is_Form",
		"not_string", "not_table", "not_player_or_name", "not_ItemStack", "not_Player", "not_coordinate", --"not_Form",

		"itemstring", "itemname", "number", "integer", "indexed", "hashed", "in_array",
		"is_itemstring", "is_itemname", "is_number", "is_integer", "is_indexed", "is_hashed", "is_in_array",
		"not_itemstring", "not_itemname", "not_number", "not_integer", "not_indexed", "not_hashed", "not_in_array",

		"is_true", "is_false", "is_nil", "not_nil", "is_function", "not_function",
	}},

	-- Mineunit / engine shared
	"dump",

	-- Mineunit
	"fixture", "fixture_path", "sourcefile",
	mineunit = { fields = {
		-- static functions
		"dofile", -- function (path, ...)
		"export_object", -- function (obj, def)
		"loadfile", -- function (path, ...)
		"format", -- function (fmtstr, ...)
		-- instance methods
		"apply_default_settings", -- function (self, settings)
		"builtin", -- function (self, name)
		"clear_InvRef", -- function (self, thing)
		"config", -- function (self, key)
		"config_set", -- function (self, key, value)
		"create_auth", -- function (self, data)
		"debugf", -- function (self, fmtstr, ...)
		"debug", -- function (self, ...)
		"DEPRECATED", -- function (self, msg)
		"destroy_nodetimer", -- function (self, pos)
		"errorf", -- function (self, fmtstr, ...)
		"error", -- function (self, ...)
		"execute_entitystep", -- function (self, dtime, filter)
		"execute_globalstep", -- function (self, dtime)
		"execute_modchannel_message", -- function (self, channel, sender, message)
		"execute_modchannel_signal", -- function (self, channel, signal)
		"execute_on_chat_message", -- function (self, sender, message)
		"execute_on_joinplayer", -- function (self, player, options)
		"execute_on_leaveplayer", -- function (self, player, timeout)
		"execute_on_player_receive_fields", -- function (self, player, formname, fields)
		"execute_shutdown", -- function (self, )
		"fs_copy", -- function (self, src, dst)
		"fs_getfile", -- function (self, path)
		"fs_raw", -- function (self, )
		"fs_reset", -- function (self, )
		"get_current_modname", -- function (self, )
		"get_entities", -- function (self, )
		"get_InvRef_data", -- function (self, thing)
		"get_modpath", -- function (self, name)
		"get_player_formspec", -- function (self, player_or_name)
		"get_players", -- function (self, )
		"get_worldpath", -- function (self, )
		"has_module", -- function (self, name)
		"infof", -- function (self, fmtstr, ...)
		"info", -- function (self, ...)
		"mods_loaded", -- function (self, )
		"prepend_flush", -- function (self, )
		"prepend_print", -- function (self, s)
		"printf", -- function (self, fmtstr, ...)
		"print", -- function (self, ...)
		"protect", -- function (self, pos, name_or_player)
		"register_on_mods_loaded", -- function (self, func)
		"restore_current_modname", -- function (self, )
		"set_current_modname", -- function (self, name)
		"set_modpath", -- function (self, name, path)
		"set_timeofday", -- function (self, d)
		"subscribe", -- function (self, what, callback)
		"warningf", -- function (self, fmtstr, ...)
		"warning", -- function (self, ...)
		-- subtables and other objects
		CraftManager = {},
		Form = {},
		utils = { fields = {
			"count", -- function (t)
			"explode_version", -- function(versionstring, default)
			"format_coordinate", -- function (t)
			--"has_item", -- assertion validator, should probably be removed
			"in_array", -- function (t, value)
			"is_coordinate", -- function (thing)
			"is_valid_name", -- function (name)
			"luatype", -- function (thing)
			"noop", -- function (...)
			"round", -- function (value)
			"sequential", -- function (t)
			"tabletype", -- function (t)
			"type", -- function (thing)
		}},
		debughooks = { fields = {
			"available",
			"noop",
			"restore",
			"delete",
			"push",
			"pop",
			"get",
			"call",
			"reset",
			"enable",
			"disable",
		}},
	}},
	"world",
	"NodeTimerRef", "MetaDataRef", "NodeMetaRef", "ObjectRef", "InvRef", "Player",

	-- Engine
	"core", "minetest",

	"INIT", "PLATFORM", "DIR_DELIM",
	string = {fields = {"split", "trim"}},
	table = {fields = {"copy", "getn", "indexof", "insert_all", "key_value_swap", "shuffle"}},
	math = {fields = {"hypot", "sign", "factorial"}},
	vector = {fields = {"new", "add", "subtract", "direction", "round", "floor", "divide", "multiply", "sort"}},
	"PseudoRandom", "ItemStack", "VoxelArea", "VoxelManip", "Settings",

}