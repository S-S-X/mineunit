local pl_path = require('pl.path')
local sequential = mineunit.utils.sequential

local default_config = {
	verbose = 2,
	print = true,
	modname = "mineunit",
	root = ".",
	mineunit_path = debug.getinfo(1).source:match("@?(.*)/"),
	spec_path = "spec",
	fixture_paths = {
		"spec/fixtures"
	},
	source_path = ".",
	time_step = -1,
	engine_version = "mineunit",
	deprecated = "throw",
	deprecated_mineunit = "error",
	singleplayer = true
}

local mineunit_conf_override = rawget(mineunit, "mineunit_conf_override") or {}
for k,v in pairs(rawget(mineunit, "mineunit_conf_defaults") or {}) do
	default_config[k] = v
end
rawset(mineunit, "mineunit_conf_defaults", nil)

mineunit._config = {
	modpaths = {},
}

function mineunit:config(key)
	if self._config[key] ~= nil then
		return self._config[key]
	end
	return default_config[key]
end

mineunit._config.source_path = pl_path.normpath(
	("%s/%s"):format(mineunit:config("root"), mineunit:config("source_path"))
)

function mineunit:config_set(key, value)
	self:debugf("Updating configuration '%s' from '%s' to '%s'", key, self._config[key], value)
	self._config[key] = value
end

local function spec_path(name)
	local path = pl_path.normpath(("%s/%s/%s"):format(mineunit:config("root"), mineunit:config("spec_path"), name))
	if pl_path.isfile(path) then
		mineunit:debugf("spec_path('%s') -> '%s'", name, path)
		return path
	end
	mineunit:debugf("spec_path, file not found: '%s'", path)
end

local function deep_merge(data, target, defaults)
	if sequential(data) and #data > 0 then
		assert(sequential(defaults), "Configuration: attempt to merge indexed table with hash table")
		-- Indexed arrays merge strategy: discard keys, add unique values
		local seen = {}
		for _,value in ipairs(defaults) do
			table.insert(target, value)
			seen[value] = true
		end
		for _,value in ipairs(data) do
			assert(type(value) ~= "table", "Configuration: tables not supported in indexed arrays")
			if not seen[value] then
				table.insert(target, value)
				mineunit:debugf("\t%d\t=\t'%s'", #target, value)
			else
				mineunit:debugf("\tSkipping duplicate value: %s", value)
			end
		end
	else
		-- Hash tables merge strategy: preserve keys, override values
		for key,value in pairs(data) do
			if defaults[key] ~= nil then
				assert(type(value) == type(defaults[key]), "Configuration: invalid data type for key", key)
				if type(value) == "table" then
					target[key] = {}
					mineunit:debugf("Configuration: merging indexed array at '%s'", key)
					deep_merge(value, target[key], defaults[key])
				else
					target[key] = value
				end
				mineunit:debugf("Configuration: '%s' = '%s'", key, value)
			elseif key ~= "exclude" then
				-- Excluding "exclude" is hack and on todo list, mineunit cli runner uses this configuration key
				mineunit:warningf("Configuration: invalid key '%s'", key)
			end
		end
	end
end

do -- Read mineunit config file
	local configpath = spec_path("mineunit.conf")
	if not configpath then
		mineunit:infof("configpath, file not found: '%s'", configpath)
	end
	if configpath then
		local configfile, err = mineunit.loadfile(configpath)
		if configfile then
			local configenv = {}
			setfenv(configfile, configenv)
			configfile()
			deep_merge(configenv, mineunit._config, default_config)
			-- Override config
			if mineunit_conf_override then
				for k, v in pairs(mineunit_conf_override) do
					mineunit._config[k] = v
				end
			end
			mineunit:infof("Mineunit configuration loaded from '%s'", configpath)
		else
			mineunit:warningf("Mineunit configuration failed: %s", err)
		end
	else
		mineunit:warning("Mineunit configuration file not found")
	end
end

local function source_path(name)
	local cfg_source_path = mineunit:config("source_path")
	local path = pl_path.normpath(("%s/%s"):format(cfg_source_path, name))
	mineunit:debugf("source_path('%s') -> '%s'", name, path)
	return path
end

-- Read mod.conf config file
local function read_mod_config()
	local modconfpath = source_path("mod.conf")
	if not modconfpath then
		mineunit:infof("mod.conf not found: '%s'", modconfpath)
		return
	end
	local configfile = io.open(modconfpath, "r")
	if configfile then
		for line in configfile:lines() do
			local key, value = string.gmatch(line, "([^=%s]+)%s*=%s*(.-)%s*$")()
			if key == "name" then
				if mineunit._config["modname"] then
					mineunit:warning("Mod name defined in both mod.conf and mineunit.conf, using mineunit.conf")
				else
					mineunit._config["modname"] = value
				end
			end
		end
		mineunit:infof("Mod configuration loaded from '%s'", modconfpath)
	else
		mineunit:warning("Loading file mod.conf failed")
	end
end
read_mod_config()

-- Save original modname and set modpath
mineunit._config["original_modname"] = mineunit:config("modname")
