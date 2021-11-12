
local Settings = {}

local default_settings = {
	language = "",
	name = "",
	bind_address = "",
	serverlist_url = "servers.minetest.net",

	-- Client
	address = "",
	enable_sound = "true",
	sound_volume = "0.8",
	mute_sound = "false",
	enable_mesh_cache = "false",
	mesh_generation_interval = "0",
	meshgen_block_cache_size = "20",
	enable_vbo = "true",
	free_move = "false",
	pitch_move = "false",
	fast_move = "false",
	noclip = "false",
	screenshot_path = "screenshots",
	screenshot_format = "png",
	screenshot_quality = "0",
	client_unload_unused_data_timeout = "600",
	client_mapblock_limit = "7500",
	enable_build_where_you_stand = "false",
	curl_timeout = "20000",
	curl_parallel_limit = "8",
	curl_file_download_timeout = "300000",
	curl_verify_cert = "true",
	enable_remote_media_server = "true",
	enable_client_modding = "false",
	max_out_chat_queue_size = "20",
	pause_on_lost_focus = "false",
	enable_register_confirmation = "true",
	clickable_chat_weblinks = "false",
	chat_weblink_color = "#8888FF",

	-- Keymap
	remote_port = "30000",
	keymap_forward = "KEY_KEY_W",
	keymap_autoforward = "",
	keymap_backward = "KEY_KEY_S",
	keymap_left = "KEY_KEY_A",
	keymap_right = "KEY_KEY_D",
	keymap_jump = "KEY_SPACE",
	keymap_sneak = "KEY_LSHIFT",
	keymap_dig = "KEY_LBUTTON",
	keymap_place = "KEY_RBUTTON",
	keymap_drop = "KEY_KEY_Q",
	keymap_zoom = "KEY_KEY_Z",
	keymap_inventory = "KEY_KEY_I",
	keymap_aux1 = "KEY_KEY_E",
	keymap_chat = "KEY_KEY_T",
	keymap_cmd = "/",
	keymap_cmd_local = ".",
	keymap_minimap = "KEY_KEY_V",
	keymap_console = "KEY_F10",
	keymap_rangeselect = "KEY_KEY_R",
	keymap_freemove = "KEY_KEY_K",
	keymap_pitchmove = "KEY_KEY_P",
	keymap_fastmove = "KEY_KEY_J",
	keymap_noclip = "KEY_KEY_H",
	keymap_hotbar_next = "KEY_KEY_N",
	keymap_hotbar_previous = "KEY_KEY_B",
	keymap_mute = "KEY_KEY_M",
	keymap_increase_volume = "",
	keymap_decrease_volume = "",
	keymap_cinematic = "",
	keymap_toggle_block_bounds = "",
	keymap_toggle_hud = "KEY_F1",
	keymap_toggle_chat = "KEY_F2",
	keymap_toggle_fog = "KEY_F3",
	keymap_toggle_update_camera = "",
	keymap_toggle_debug = "KEY_F5",
	keymap_toggle_profiler = "KEY_F6",
	keymap_camera_mode = "KEY_KEY_C",
	keymap_screenshot = "KEY_F12",
	keymap_increase_viewing_range_min = "+",
	keymap_decrease_viewing_range_min = "-",
	keymap_slot1 = "KEY_KEY_1",
	keymap_slot2 = "KEY_KEY_2",
	keymap_slot3 = "KEY_KEY_3",
	keymap_slot4 = "KEY_KEY_4",
	keymap_slot5 = "KEY_KEY_5",
	keymap_slot6 = "KEY_KEY_6",
	keymap_slot7 = "KEY_KEY_7",
	keymap_slot8 = "KEY_KEY_8",
	keymap_slot9 = "KEY_KEY_9",
	keymap_slot10 = "KEY_KEY_0",
	keymap_slot11 = "",
	keymap_slot12 = "",
	keymap_slot13 = "",
	keymap_slot14 = "",
	keymap_slot15 = "",
	keymap_slot16 = "",
	keymap_slot17 = "",
	keymap_slot18 = "",
	keymap_slot19 = "",
	keymap_slot20 = "",
	keymap_slot21 = "",
	keymap_slot22 = "",
	keymap_slot23 = "",
	keymap_slot24 = "",
	keymap_slot25 = "",
	keymap_slot26 = "",
	keymap_slot27 = "",
	keymap_slot28 = "",
	keymap_slot29 = "",
	keymap_slot30 = "",
	keymap_slot31 = "",
	keymap_slot32 = "",

	-- Some (temporary) keys for debugging
	keymap_quicktune_prev = "KEY_HOME",
	keymap_quicktune_next = "KEY_END",
	keymap_quicktune_dec = "KEY_NEXT",
	keymap_quicktune_inc = "KEY_PRIOR",

	-- Visuals
	show_debug = "false",
	fsaa = "0",
	undersampling = "0",
	world_aligned_mode = "enable",
	autoscale_mode = "disable",
	enable_fog = "true",
	fog_start = "0.4",
	["3d_mode"] = "none",
	["3d_paralax_strength"] = "0.025",
	tooltip_show_delay = "400",
	tooltip_append_itemname = "false",
	fps_max = "60",
	fps_max_unfocused = "20",
	viewing_range = "190",
	screen_w = "1024",
	screen_h = "600",
	autosave_screensize = "true",
	fullscreen = "false",
	vsync = "false",
	fov = "72",
	leaves_style = "fancy",
	connected_glass = "false",
	smooth_lighting = "true",
	lighting_alpha = "0.0",
	lighting_beta = "1.5",
	display_gamma = "1.0",
	lighting_boost = "0.2",
	lighting_boost_center = "0.5",
	lighting_boost_spread = "0.2",
	texture_path = "",
	shader_path = "",
	video_driver = "opengl",
	cinematic = "false",
	camera_smoothing = "0",
	cinematic_camera_smoothing = "0.7",
	enable_clouds = "true",
	view_bobbing_amount = "1.0",
	fall_bobbing_amount = "0.03",
	enable_3d_clouds = "true",
	cloud_radius = "12",
	menu_clouds = "true",
	opaque_water = "false",
	console_height = "0.6",
	console_color = "(0,0,0)",
	console_alpha = "200",
	formspec_fullscreen_bg_color = "(0,0,0)",
	formspec_fullscreen_bg_opacity = "140",
	formspec_default_bg_color = "(0,0,0)",
	formspec_default_bg_opacity = "140",
	selectionbox_color = "(0,0,0)",
	selectionbox_width = "2",
	node_highlighting = "box",
	crosshair_color = "(255,255,255)",
	crosshair_alpha = "255",
	recent_chat_messages = "6",
	hud_scaling = "1.0",
	gui_scaling = "1.0",
	gui_scaling_filter = "false",
	gui_scaling_filter_txr2img = "true",
	desynchronize_mapblock_texture_animation = "true",
	hud_hotbar_max_width = "1.0",
	enable_local_map_saving = "false",
	show_entity_selectionbox = "false",
	texture_clean_transparent = "false",
	texture_min_size = "64",
	ambient_occlusion_gamma = "1.8",
	enable_shaders = "true",
	enable_particles = "true",
	arm_inertia = "true",
	show_nametag_backgrounds = "true",

	enable_minimap = "true",
	minimap_shape_round = "true",
	minimap_double_scan_height = "true",

	-- Effects
	directional_colored_fog = "true",
	inventory_items_animations = "false",
	mip_map = "false",
	anisotropic_filter = "false",
	bilinear_filter = "false",
	trilinear_filter = "false",
	tone_mapping = "false",
	enable_waving_water = "false",
	water_wave_height = "1.0",
	water_wave_length = "20.0",
	water_wave_speed = "5.0",
	enable_waving_leaves = "false",
	enable_waving_plants = "false",

	-- Effects Shadows
	enable_dynamic_shadows = "false",
	shadow_strength = "0.2",
	shadow_map_max_distance = "200.0",
	shadow_map_texture_size = "2048",
	shadow_map_texture_32bit = "true",
	shadow_map_color = "false",
	shadow_filters = "1",
	shadow_poisson_filter = "true",
	shadow_update_frames = "8",
	shadow_soft_radius = "1.0",
	shadow_sky_body_orbit_tilt = "0.0",

	-- Input
	invert_mouse = "false",
	mouse_sensitivity = "0.2",
	repeat_place_time = "0.25",
	safe_dig_and_place = "false",
	random_input = "false",
	aux1_descends = "false",
	doubletap_jump = "false",
	always_fly_fast = "true",
	autojump = "false",
	continuous_forward = "false",
	enable_joysticks = "false",
	joystick_id = "0",
	joystick_type = "",
	repeat_joystick_button_time = "0.17",
	joystick_frustum_sensitivity = "170",
	joystick_deadzone = "2048",

	-- Main menu
	main_menu_path = "",
	serverlist_file = "favoriteservers.json",

	freetype = "false",
	font_path = fixture_path("fonts"),
	mono_font_path = fixture_path("fonts"),

	-- General font settings
	font_size = "10",
	mono_font_size = "10",
	chat_font_size = "0", -- Default "font_size"

	-- ContentDB
	contentdb_url = "https://content.minetest.net",
	contentdb_max_concurrent_downloads = "3",

	contentdb_flag_blacklist = "nonfree, desktop_default",

	-- Server
	disable_escape_sequences = "false",
	strip_color_codes = "false",

	-- Network
	enable_ipv6 = "true",
	ipv6_server = "false",
	max_packets_per_iteration = "1024",
	port = "30000",
	strict_protocol_version_checking = "false",
	player_transfer_distance = "0",
	max_simultaneous_block_sends_per_client = "40",
	time_send_interval = "5",

	default_game = "minetest",
	motd = "",
	max_users = "15",
	creative_mode = "false",
	enable_damage = "true",
	default_password = "",
	default_privs = "interact, shout",
	enable_pvp = "true",
	enable_mod_channels = "false",
	disallow_empty_password = "false",
	disable_anticheat = "false",
	enable_rollback_recording = "false",
	deprecated_lua_api_handling = "log",

	kick_msg_shutdown = "Server shutting down.",
	kick_msg_crash = "This server has experienced an internal error. You will now be disconnected.",
	ask_reconnect_on_crash = "false",

	chat_message_format = "<@name> @message",
	profiler_print_interval = "0",
	active_object_send_range_blocks = "8",
	active_block_range = "4",
	max_block_send_distance = "12",
	block_send_optimize_distance = "4",
	server_side_occlusion_culling = "true",
	csm_restriction_flags = "62",
	csm_restriction_noderange = "0",
	max_clearobjects_extra_loaded_blocks = "4096",
	time_speed = "72",
	world_start_time = "6125",
	server_unload_unused_data_timeout = "29",
	max_objects_per_block = "64",
	server_map_save_interval = "5.3",
	chat_message_max_size = "500",
	chat_message_limit_per_10sec = "8.0",
	chat_message_limit_trigger_kick = "50",
	sqlite_synchronous = "2",
	map_compression_level_disk = "-1",
	map_compression_level_net = "-1",
	full_block_send_enable_min_time_from_building = "2.0",
	dedicated_server_step = "0.09",
	active_block_mgmt_interval = "2.0",
	abm_interval = "1.0",
	abm_time_budget = "0.2",
	nodetimer_interval = "0.2",
	ignore_world_load_errors = "false",
	remote_media = "",
	debug_log_level = "action",
	debug_log_size_max = "50",
	chat_log_level = "error",
	emergequeue_limit_total = "1024",
	emergequeue_limit_diskonly = "128",
	emergequeue_limit_generate = "128",
	num_emerge_threads = "1",
	["secure.enable_security"] = "true",
	["secure.trusted_mods"] = "",
	["secure.http_mods"] = "",

	-- Physics
	movement_acceleration_default = "3",
	movement_acceleration_air = "2",
	movement_acceleration_fast = "10",
	movement_speed_walk = "4",
	movement_speed_crouch = "1.35",
	movement_speed_fast = "20",
	movement_speed_climb = "3",
	movement_speed_jump = "6.5",
	movement_liquid_fluidity = "1",
	movement_liquid_fluidity_smooth = "0.5",
	movement_liquid_sink = "10",
	movement_gravity = "9.81",

	-- Liquids
	liquid_loop_max = "100000",
	liquid_queue_purge_time = "0",
	liquid_update = "1.0",

	-- Mapgen
	mg_name = "v7",
	water_level = "1",
	mapgen_limit = "31000",
	chunksize = "5",
	fixed_map_seed = "",
	max_block_generate_distance = "10",
	enable_mapgen_debug_info = "false",
	--TODO: Mapgen::setDefaultSettings(settings);

	-- Server list announcing
	server_announce = "false",
	server_url = "",
	server_address = "",
	server_name = "",
	server_description = "",

	enable_console = "false",
	screen_dpi = "72",
	display_density_factor = "1",
}

-- https://github.com/minetest/minetest/blob/master/src/util/string.h
local function is_yes(value)
	if tonumber(value) then
		return tonumber(value) ~= 0
	end
	value = tostring(value):lower()
	return (value == "y" or value == "yes" or value == "true")
end

function Settings:get(key)
	mineunit:debug("Settings:get(...)", key, self._data[key])
	return self._data[key]
end

function Settings:get_bool(key, default)
	local value = self._data[key]
	mineunit:debug("Settings:get_bool(...)", key, value and is_yes(value) or value, default)
	if value == nil then
		return default
	end
	return is_yes(value)
end

function Settings:set(key, value)
	self._data[key] = tostring(value)
end

function Settings:set_bool(key, value)
	self:set(key, value and "true" or "false")
end

function Settings:write(...)
	-- noop / not implemented
	mineunit:info("Settings:write(...) called, no operation")
end

function Settings:remove(key)
	mineunit:debug("Settings:remove(...)", key, self._data[key])
	self._data[key] = nil
	return true
end

function Settings:get_names()
	local result = {}
	for k,_ in pairs(t) do
		table.insert(result, k)
	end
	return result
end

function Settings:to_table()
	local result = {}
	for k,v in pairs(self._data) do
		result[k] = v
	end
	return result
end

local function load_conf_file(fname, target)
	file = io.open(fname, "r")
	if file then
		mineunit:debug("Settings object loading values from:", fname)
		for line in file:lines() do
			for key, value in string.gmatch(line, "([^=%s]+)%s*=%s*(.-)%s*$") do
				mineunit:debug("\t", key, "=", value)
				target[key] = value
			end
		end
		mineunit:info("Settings object created from:", fname)
		return true
	end
end

mineunit.export_object(Settings, {
	name = "Settings",
	constructor = function(self, fname)
		local settings = {}
		settings._data = {}
		-- Not even nearly perfect config parser but should be good enough for now
		if not load_conf_file(fname, settings._data) then
			if not load_conf_file(fixture_path(fname), settings._data) then
				mineunit:info("File not found, creating empty Settings object:", fname)
			end
		end
		setmetatable(settings, Settings)
		settings.__index = settings
		return settings
	end,
})

function mineunit:apply_default_settings(settings)
	local data = settings._data
	for key, value in pairs(default_settings) do
		if data[key] == nil then
			data[key] = value
		end
	end
end
