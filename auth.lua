mineunit("player")

-- AuthEntry class

local valid_name = mineunit.utils.is_valid_name

local last_unique_id = -1
local function unique_id()
	last_unique_id = last_unique_id + 1
	return last_unique_id
end

local AuthEntry = {}

mineunit.export_object(AuthEntry, {
	name = "AuthEntry",
	typename = "table",
	constructor = function(self, data)
		local obj = {
			id = unique_id(),
			name = assert(data.name, "Invalid AuthEntry name"),
			password = type(data.password) == "string" and data.password or "",
			privileges = data.privileges,
			last_login = data.last_login or -1,
		}
		setmetatable(obj, AuthEntry)
		return obj
	end,
})

-- Engine core.auth

local auth = {}

local entries = {}

function auth.read(name)
	-- Return value only when available, never return nil
	if entries[name] then
		return entries[name]
	end
end

function auth.save(entry)
	assert.is_table(entry)
	local player = mineunit:get_players()[entry.name]
	if player then
		player._privs = entry.privileges
	end
	return true
end

function auth.create(data)
	mineunit:info("auth.create(data) called")
	assert.is_table(data, "auth.create(data): table required")
	assert.is_table(data.privileges, "auth.create(data): privileges table invalid or missing.")
	assert.is_integer(data.last_login, "auth.create(data): last_login must be integer value.")
	if valid_name(data.name) then
		local entry = AuthEntry(data)
		entries[entry.name] = entry
	else
		-- TODO: This can be skipped when not in strict mode, checking for string type is still mandatory
		error("auth.create(data): invalid player name: "..tostring(data.name))
	end
end

function auth.delete(name)
	mineunit:info("auth.delete() called")
	entries[name] = nil
end

function auth.list_names()
	mineunit:info("auth.list_names() called")
end

function auth.reload()
	mineunit:info("auth.reload() called")
end

function mineunit:create_auth(data)
	-- Assume correct parameters
	local entry = AuthEntry(data)
	entries[entry.name] = entry
end

_G.core.auth = auth

mineunit("game/auth")
