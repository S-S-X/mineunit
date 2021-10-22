mineunit("player")

-- AuthEntry class

local last_unique_id = -1
local function unique_id()
	last_unique_id = last_unique_id + 1
	return last_unique_id
end

local AuthEntry = {}

mineunit.export_object(AuthEntry, {
	name = "AuthEntry",
	typename = "table",
	constructor = function(self, name)
		assert(type(name) == "string")
		local obj = {}
		local player = mineunit:get_players()[name]
		assert.is_player(player)
		obj.id = unique_id()
		obj.name = name
		obj.privileges = player._privs
		obj.password = ""
		obj.last_login = 0
		setmetatable(obj, AuthEntry)
		return obj
	end,
})

-- Engine core.auth

local auth = {}

local entries = {}

function auth.read(name)
	if not entries[name] then
		entries[name] = AuthEntry(name)
	end
	return entries[name]
end

function auth.save(entry)
	local player = mineunit:get_players()[entry.name]
	assert.is_Player(player)
	player._privs = entry.privileges
end

function auth.create()
	mineunit:info("auth.create() called")
end

function auth.delete()
	mineunit:info("auth.delete() called")
end

function auth.list_names()
	mineunit:info("auth.list_names() called")
end

function auth.reload()
	mineunit:info("auth.reload() called")
end

_G.core.auth = auth

mineunit("game/auth")
