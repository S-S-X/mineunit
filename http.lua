
-- TODO: Add HTTP "server" object that can hold response state
-- mineunit:set_http_server_next_response(response_object)

mineunit("game/misc")

local handle = 0

local httpenv = {
	fetch_async = function(req)
		mineunit:info("HTTPApiTable.fetch_async called")
		handle = handle + 1
		return handle
	end,
	fetch_async_get = function(handle)
		mineunit:info("HTTPApiTable.fetch_async_get called")
		return {
			completed = true,
			succeeded = true,
			timeout = false,
			code = 200,
			data = "response"
		}
	end,
}

core.http_add_fetch(httpenv)

local function create_http_api()
	return httpenv
end

function core.request_http_api()
	local http_mods = core.settings:get("secure.http_mods")
	local trusted_mods = core.settings:get("secure.trusted_mods")
	http_mods = (http_mods and trusted_mods) and http_mods..","..trusted_mods or http_mods or trusted_mods

	if http_mods then
		local current_modname  = mineunit:get_current_modname()
		for modname in http_mods:gmatch("[^%s,]+") do
			if modname == current_modname then
				return create_http_api()
			end
		end
	end
	mineunit:warning("Called core.request_http_api() without being in secure.http_mods or secure.trusted_mods", modname)
end
