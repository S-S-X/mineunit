-- For self tests package path must be set in a way that makes package loaders search current directory first
package.path = "./?.lua;../?/init.lua;../?.lua;" --.. package.path

describe("Mineunit auth", function()

	require("mineunit")
	mineunit:config_set("silence_global_export_overrides", true)
	sourcefile("core")
	sourcefile("player")
	mineunit("auth")

	local SX = Player("SX")

	it("creates new entry with mineunit:create_auth(data)", function()
		mineunit:config_set("singleplayer", false)
		local auth_data = {
			name = "auth-p1",
			password = "pass-p1",
			privileges = {},
			last_login = 123
		}
		mineunit:create_auth(auth_data)
		-- Read auth entry
		local auth_handler = core.get_auth_handler()
		local auth_entry = auth_handler.get_auth("auth-p1")
		assert.not_equals(auth_data, auth_entry)
		assert.same({
			password = "pass-p1",
			privileges = {},
			last_login = 123
		}, auth_entry)
	end)

	it("creates new entry for Player instance", function()
		mineunit:config_set("singleplayer", false)
		-- New Player instance
		spy.on(mineunit, "create_auth")
		local player = Player("auth-p2", { priv31 = true, priv32 = true })
		assert.spy(mineunit.create_auth).called()
		-- Read auth entry
		local auth_handler = core.get_auth_handler()
		local auth_entry = auth_handler.get_auth("auth-p2")
		assert.same({
			password = "",
			privileges = {
				priv31 = true,
				priv32 = true,
			},
			last_login = 0
		}, auth_entry)
	end)

	it("creates new entry with engine auth handler with configured privileges", function()
		mineunit:config_set("singleplayer", false)
		-- Create new auth entry
		local auth_handler = core.get_auth_handler()
		auth_handler.create_auth("auth-p3", "pass-p3")
		-- Try to read it back
		local auth_entry = auth_handler.get_auth("auth-p3")
		assert.same({
			password = "pass-p3",
			privileges = {
				interact = true,
			},
			last_login = -1
		}, auth_entry)
	end)

	it("new singleplayer Player instance has default privileges", function()
		mineunit:config_set("singleplayer", true)
		-- New Player instance
		spy.on(mineunit, "create_auth")
		local player = Player("auth-p4", { priv41 = true, priv42 = true })
		assert.spy(mineunit.create_auth).called()
		-- Read auth entry
		local auth_handler = core.get_auth_handler()
		local auth_entry = auth_handler.get_auth("auth-p4")
		assert.same({
			password = "",
			privileges = {
				priv41 = true, -- explicit constructor privileges
				priv42 = true,
				interact = true, -- give_to_singleplayer privileges
				shout = true,
				basic_privs = true,
				privs = true,
			},
			last_login = 0
		}, auth_entry)
	end)

end)