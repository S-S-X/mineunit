local io = io
local pl_path = require('pl.path')

local lua_dofile = dofile
local lua_loadfile = loadfile
if mineunit == nil then
	mineunit = {}
	function mineunit.dofile(path)
		return lua_dofile(pl_path.normpath(path))
	end
	function mineunit.loadfile(path, ...)
		return lua_loadfile(pl_path.normpath(path), ...)
	end
else
	mineunit.dofile = lua_dofile
	mineunit.loadfile = lua_loadfile
end
mineunit.__index = mineunit

local assert = require('luassert.assert')
mineunit.utils = require("mineunit.assert")
require("mineunit.print")
require("mineunit.config")
require("mineunit.globals")

local hooks = mineunit.debughooks

mineunit._on_mods_loaded = {}
mineunit._on_mods_loaded_exec_count = 0

local tagged_paths = {
	["."] = true,
	["common"] = true,
	["game"] = true
}

local blacklist_names = {
	["common/strict"] = true,
}

local preload_modules = {
	["game/auth"] = "auth",
}

function _G.dofile(path)
	return hooks:get(mineunit.dofile, path)
end

function _G.loadfile(path, ...)
	return hooks:get(mineunit.loadfile, path, ...)
end

local builtins = {
	debug = debug,
	os = os,
	io = io,
}

local alternative_modules = {}
local function add_alternative_module(name)
	assert(alternative_modules[name] == nil)
	alternative_modules[name] = require("mineunit."..name)
end

local _mineunits = {}
local _subloader_preload

local function require_filter(path, namepattern, loader, ...)
	path = pl_path.normpath(path)
	local name = path:gsub(namepattern, "%1")
	if _mineunits[name] then
		mineunit:debugf("Potential source of errors: reusing %s", name)
		return _mineunits[name]
	elseif blacklist_names[name] then
		mineunit:debugf("Loader blacklisted %s", name)
		return
	end
	mineunit:debugf("Loader accepted %s", name)
	if preload_modules[name] then
		mineunit:debugf("Loader preloading %s for %s", preload_modules[name], name)
		_subloader_preload = name
		mineunit(preload_modules[name], { strict = true })
		--_mineunits[name] = {require_mineunit(redirect_names[name], nil, nil, true)}
		--return _mineunits[name]
	end
	local result = {loader(path, ...)}
	_mineunits[name] = result
	return result
end

local _subloader_active = false
local function require_mineunit(name, root, tag, strict)
	mineunit:debugf("Loading mineunit module %s", name)
	local modulename = name:gsub("/", ".")
	if root and tag and tag ~= "mineunit" then
		local path = name:match("^([^/]+)/")
		if path and tagged_paths[path] then
			mineunit:debugf("Loading %s from %s (%s)", name, tag, _subloader_active)
			local namepattern = "^.*/" .. tag:gsub("([%.%-%+%*%%%(%)%[%]])", "%%%1") .. "/(.*)%.lua$"
			local oldpath = package.path
			local module, original_dofile, original_loadfile
			if not _subloader_active then
				mineunit:debug("Enabling loader overrides")
				local newpath = root.."/"..tag.."/?.lua;"
				package.path = newpath
				original_dofile = rawget(_G, "dofile")
				original_loadfile = rawget(_G, "loadfile")
				rawset(_G, "dofile", function (fpath)
					_subloader_active = true
					package.path = oldpath
					local submod = require_filter(fpath, namepattern, lua_dofile)
					package.path = newpath
					_subloader_active = false
					return submod and unpack(submod) or nil
				end)
				rawset(_G, "loadfile", function (fpath, ...)
					_subloader_active = true
					package.path = oldpath
					local submod = require_filter(fpath, namepattern, lua_loadfile, ...)
					package.path = newpath
					_subloader_active = false
					return submod and unpack(submod) or nil
				end)
			end
			local success, err = pcall(function() module = require(modulename) end)
			if not _subloader_active then
				mineunit:debug("Disabling loader overrides")
				rawset(_G, "dofile", original_dofile)
				rawset(_G, "loadfile", original_loadfile)
				package.path = oldpath
			end
			if success then
				mineunit:debugf("Loaded %s from %s", name, tag)
				return module
			elseif strict or _subloader_active then
				mineunit:error(err)
				mineunit:errorf("Loading %s from %s failed", name, tag)
				error("Loading " .. name .. " from " .. tag .. " failed")
			else
				mineunit:debug(err)
				mineunit:errorf("Loading %s from %s failed, trying builtin", name, tag)
			end
		end
	end
	return require("mineunit." .. modulename)
end

setmetatable(mineunit, {
	__call = function(self, name, options)
		if name == _subloader_preload then
			mineunit:debugf("Loader skipping queued module %s", name)
			return
		end
		hooks:pop()
		if _mineunits[name] == nil then
			if alternative_modules[name] then
				_mineunits[name] = {alternative_modules[name]()}
			else
				local core_root = mineunit:config("core_root")
				local engine_version = mineunit:config("engine_version")
				local strict = options and options.strict
				_mineunits[name] = {require_mineunit(name, core_root, engine_version, strict)}
			end
		end
		hooks:push()
		return unpack(_mineunits[name])
	end,
})

function mineunit:builtin(name)
	return builtins[name]
end

function mineunit:has_module(name)
	return _mineunits[name] and true
end

function mineunit:set_modpath(name, path)
	path = pl_path.normpath(path)
	mineunit:infof("Setting modpath of '%s' to '%s'", name, path)
	self._config.modpaths[name] = path
end

function mineunit:get_modpath(name)
	return self._config.modpaths[name]
end

function mineunit:get_current_modname()
	return self:config("modname")
end

function mineunit:set_current_modname(name)
	self._config.modname = name
end

function mineunit:restore_current_modname()
	self._config.modname = self:config("original_modname")
end

function mineunit:get_worldpath()
	return self:config("fixture_paths")[1]
end

function mineunit:register_on_mods_loaded(func)
	if self._on_mods_loaded_exec_count > 0 then
		mineunit:warning("mineunit:register_on_mods_loaded: Registering after registered_on_mods_loaded executed")
	end
	assert(type(func) == "function", "register_on_mods_loaded requires function, got "..type(func))
	table.insert(self._on_mods_loaded, func)
end

function mineunit:mods_loaded()
	hooks:pop()
	if self._on_mods_loaded then
		mineunit:info("Executing register_on_mods_loaded functions")
		if self._on_mods_loaded_exec_count > 0 then
			mineunit:warningf("mineunit:mods_loaded: Callbacks already executed %d times", self._on_mods_loaded_exec_count)
		end
		if core.registered_on_mods_loaded then
			for index, func in ipairs(core.registered_on_mods_loaded) do
				if self._on_mods_loaded[index] ~= func then
					mineunit:warning("Unsupported registration overrides detected for core.registered_on_mods_loaded")
					local swap_index = mineunit.utils.in_array(self._on_mods_loaded, func)
					if swap_index then
						self._on_mods_loaded[swap_index], self._on_mods_loaded[index] =
							self._on_mods_loaded[index], self._on_mods_loaded[swap_index]
					else
						table.insert(self._on_mods_loaded, index, func)
					end
				end
			end
		end
		-- Enable hooks so that push, pop, call and get are usable also outside describe blocks
		local hooks_disabled = hooks:enable()
		for _,func in ipairs(self._on_mods_loaded) do
			hooks:call(func)
		end
		if hooks_disabled then
			hooks:disable()
		end
		self._on_mods_loaded_exec_count = self._on_mods_loaded_exec_count + 1
	end
	hooks:push()
end

function fixture_path(name)
	local index = name:find(mineunit:get_worldpath(), nil, true)
	if index then
		-- Remove worldpath from name, worldpath should be in search_paths.
		-- This is to allow using search_paths when mod creates Settings object from worldpath.
		name = name:sub(1, index - 1) .. name:sub(index + #mineunit:get_worldpath())
	end
	local root = mineunit:config("root")
	local search_paths = mineunit:config("fixture_paths")
	for _,search_path in ipairs(search_paths) do
		local path = pl_path.normpath(("%s/%s/%s"):format(root, search_path, name))
		if pl_path.isfile(path) then
			return path
		else
			mineunit:debugf("fixture_path, file not found: '%s'", path)
		end
	end
	local path = pl_path.normpath(("%s/%s/%s"):format(root, search_paths[1], name))
	mineunit:infof("File not found: '%s'", path)
	return path
end

local _fixtures = {}
function fixture(name)
	hooks:pop()
	local path = fixture_path(name .. ".lua")
	if not _fixtures[name] then
		mineunit:infof("Loading fixture %s", path)
		assert(pl_path.isfile(path), "Fixture not found: " .. path)
		local result = {dofile(path)}
		_fixtures[name] = result
	else
		mineunit:debugf("Fixture already loaded: %s", path)
	end
	hooks:push()
	return unpack(_fixtures[name])
end

local function source_path(name)
	local cfg_source_path = mineunit:config("source_path")
	local path = pl_path.normpath(("%s/%s"):format(cfg_source_path, name))
	mineunit:debugf("source_path('%s') -> '%s'", name, path)
	return path
end

function sourcefile(name)
	local path = source_path(name .. ".lua")
	mineunit:infof("Loading source %s", path)
	assert(pl_path.isfile(path), "Source file not found: " .. path)
	local hooks_disabled = hooks:enable()
	local module = {dofile(path)}
	if hooks_disabled then
		hooks:disable()
	end
	return unpack(module)
end

local function DEPRECATED(instance, action, msg)
	if action == "ignore" then
		return
	elseif action == "throw" then
		error(msg or "Attempted to use deprecated method")
	elseif ({debug=1,info=1,warning=1,error=1})[action] then
		instance[action](instance, msg or "Calling deprecated engine method")
	else
		error("Config: invalid value for 'deprecated'. Allowed values: throw, error, warning, info, debug, ignore.")
	end
end

function mineunit:DEPRECATED(msg)
	return DEPRECATED(self, self:config("deprecated"), msg)
end

function mineunit.export_object(obj, def)
	if not def.private and _G[def.name] ~= nil and not mineunit:config("silence_global_export_overrides") then
		mineunit:errorf("mineunit.export_object overriding already reserved global name: %s", (def.name or "?"))
	end
	if not obj.__index then
		obj.__index = obj
	end
	setmetatable(obj, {
		__call = function(...)
			local hooks_enabled = hooks:delete()
			local ins = def.constructor(...)
			ins._mineunit_typename = def.typename or def.name
			if hooks_enabled then
				hooks:restore()
			end
			return ins
		end
	})
	if not def.private then
		_G[def.name] = obj
	end
end

-- Prepare alternative modules
add_alternative_module("fs")

-- Set modpath
mineunit:set_modpath(mineunit:config("modname"), mineunit:config("root"))

mineunit("deprecation")(function(msg)
	return DEPRECATED(mineunit, mineunit:config("deprecated_mineunit"), msg)
end)

mineunit:infof("Mineunit initialized, current modname is %s", mineunit:get_current_modname())