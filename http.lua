
-- TODO: Add HTTP "server" object that can hold response state
-- mineunit:set_http_server_next_response(response_object)

mineunit("game/misc")

local function tablecopy(t)
	local result = {}
	for key, value in pairs(t) do
		result[key] = value
	end
	return result
end

--
-- Mineunit HTTP server
--

-- Default request function values will be executed with supplied value and result used as actual value
local defaultrequest = {
	url = function(url)
		assert(type(url) == "string", "HTTPRequest.url: Invalid value, string required.", url)
		return url
	end,
	timeout = 3, -- Timeout for connection in seconds. Default is 3 seconds.
	method = "GET", -- The http method to use. Defaults to "GET".
	data = nil, -- Data for the POST, PUT or DELETE request. Accepts both a string and a table.
	user_agent = "Mineunit", -- Optional, if specified replaces the default minetest user agent with given string
	extra_headers = nil, -- Optional, if specified adds additional headers to the HTTP request.
	multipart = false, -- Optional, if true performs a multipart HTTP request. Post only, data must be array
	post_data = function(post_data)
		if post_data ~= nil then
			DEPRECATED("HTTPRequest.post_data: Deprecated, use `data` instead.")
		end
	end,
}

local defaultresponse = {
	completed = true,
	succeeded = true,
	timeout = false,
	code = 200,
	data = "OK"
}

local MineunitHTTPServer = {}
MineunitHTTPServer.__index = MineunitHTTPServer

function MineunitHTTPServer:set_response(response)
	for key, value in pairs(response) do
		if defaultresponse[key] ~= nil then
			self._response[key] = value
		else
			mineunit:warning("Skipping invalid key for MineunitHTTPServer.response", key)
		end
	end
end

function MineunitHTTPServer:read(handle)
	assert(handle ~= nil, "Invalid call to MineunitHTTPServer:get_response, nil handle")
	if self._handles[handle] then
		-- Do not delete keys to make it simpler for now
		self._handles[handle] = false
		return tablecopy(self._response)
	end
end

function MineunitHTTPServer:write(req)
	assert(type(req) == "table", "Invalid call to MineunitHTTPServer:request, table required")
	-- Increment handles and return last
	local request = {}
	for key, value in pairs(defaultrequest) do
		if type(value) == "function" then
			request[key] = value(req[key])
		elseif req[key] ~= nil then
			request[key] = req[key]
		else
			request[key] = value
		end
	end
	table.insert(self._handles, request)
	return #self._handles
end

setmetatable(MineunitHTTPServer, {
	__call = function(self, def)
		local obj = {
			_handles = {},
			_response = tablecopy(defaultresponse)
		}
		if def and def._response then
			self:set_response(def.response)
		end
		setmetatable(obj, MineunitHTTPServer)
		return obj
	end,
})

mineunit.http_server = MineunitHTTPServer()

--
-- Minetest HTTP API
--

local httpenv = {
	fetch_async = function(req)
		mineunit:info("HTTPApiTable.fetch_async called", req)
		return mineunit.http_server:write(req)
	end,
	fetch_async_get = function(handle)
		mineunit:info("HTTPApiTable.fetch_async_get called", handle)
		return mineunit.http_server:read(handle)
	end,
}

-- Minetest core function to inject fetch method
core.http_add_fetch(httpenv)

function core.request_http_api()
	local http_mods = core.settings:get("secure.http_mods")
	local trusted_mods = core.settings:get("secure.trusted_mods")
	http_mods = (http_mods and trusted_mods) and http_mods..","..trusted_mods or http_mods or trusted_mods

	if http_mods then
		local current_modname  = mineunit:get_current_modname()
		for modname in http_mods:gmatch("[^%s,]+") do
			if modname == current_modname then
				return tablecopy(httpenv)
			end
		end
	end
	mineunit:warning("Called core.request_http_api() without being in secure.http_mods or secure.trusted_mods", modname)
end
