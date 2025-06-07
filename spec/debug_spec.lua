-- For self tests package path must be set in a way that makes package loaders search current directory first
package.path = "./?.lua;../?/init.lua;../?.lua;" --.. package.path

require("mineunit")

local hooks = mineunit.debughooks
if not hooks.available then
	mineunit:warning("Tests skipped: Debug hooks not available.")
	return
end

assert(debug.gethook() == nil, "Debug hooks should be disabled within spec root")
mineunit:config_set("silence_global_export_overrides", true)

local mt_not_nil = setmetatable({}, {
	__index = function()
		assert.not_nil(debug.gethook())
		return function()
			assert.not_nil(debug.gethook())
		end
	end
})

local mt_is_nil = setmetatable({}, {
	__index = function()
		assert.is_nil(debug.gethook())
		return function()
			assert.is_nil(debug.gethook())
		end
	end
})

local on_mods_loaded_called = false
core.register_on_mods_loaded(function()
	on_mods_loaded_called = true
	assert.not_nil(debug.gethook(), "Debug hooks should be enabled for core.registered_on_mods_loaded")
end)

-- Debug hooks should be disabled outside of describe() block
assert.is_nil(debug.gethook(), "Debug hooks should be disabled within spec root")

-- Debug hooks should get enabled when mods_loaded() is called from spec root
mineunit:mods_loaded()
assert.is_true(on_mods_loaded_called, "core.registered_on_mods_loaded not executed")

-- Debug hooks should still be disabled outside of describe() block
assert.is_nil(debug.gethook(), "Debug hooks should be disabled within spec root")

describe("Mineunit debug hooks", function()

	-- Should also have debug hooks in describe() body
	assert.not_nil(debug.gethook(), "Debug hooks should be enabled within describe root")

	it("it has debug hook", function()
		assert.not_nil(debug.gethook())
	end)

	describe("nested describe", function()
		assert.not_nil(debug.gethook(), "Debug hooks should be enabled within nested describe root")
		it("it has debug hook", function()
			assert.not_nil(debug.gethook())
		end)
	end)

	it("pop/push disables and enables hooks", function()
		assert.not_nil(debug.gethook())
		hooks:pop()
		assert.is_nil(debug.gethook())
		hooks:push()
		assert.not_nil(debug.gethook())
	end)

	it("nested pop/push disables and enables hooks", function()
		assert.not_nil(debug.gethook())
		-- pop x3, hooks should stay disabled
		hooks:pop()
		assert.is_nil(debug.gethook())
		hooks:pop()
		assert.is_nil(debug.gethook())
		hooks:pop()
		assert.is_nil(debug.gethook())
		-- push x3, third push should enable hooks
		hooks:push()
		assert.is_nil(debug.gethook())
		hooks:push()
		assert.is_nil(debug.gethook())
		hooks:push()
		assert.not_nil(debug.gethook())
		-- pop + push once afterwards
		hooks:pop()
		assert.is_nil(debug.gethook())
		hooks:push()
		assert.not_nil(debug.gethook())
	end)

	it("gets disabled after call", function()
		hooks:pop()
		assert.is_nil(debug.gethook())
		hooks:call(function(arg)
			assert.equals(1, arg)
			assert.not_nil(debug.gethook())
		end, 1)
		-- Debug hooks get disabled if inactive before hooks:call()
		assert.is_nil(debug.gethook())
		-- Should normally always call push after pop but we are not doing that here
		-- because debug hooks gets reset after every test case, it should also be
		-- called through finally() instead of directly as tests might fail.
		-- hooks:push()
	end)

	it("can be restored after call", function()
		hooks:pop()
		assert.is_nil(debug.gethook())
		local called = false
		hooks:call(function(arg)
			assert.equals(1, arg)
			assert.not_nil(debug.gethook())
			called = true
		end, 1)
		assert.is_true(called)
		-- Debug hooks get enabled again with hooks:push()
		hooks:push()
		assert.not_nil(debug.gethook())
	end)

	it("stays enabled after call", function()
		assert.not_nil(debug.gethook())
		local called = false
		hooks:call(function(arg)
			assert.equals(2, arg)
			assert.not_nil(debug.gethook())
			called = true
		end, 2)
		assert.is_true(called)
		-- Debug hooks stay enabled if active before hooks:call()
		assert.not_nil(debug.gethook())
	end)

	it("stays enabled for __index", function()
		-- mt_not_nil.__index first executes assert.not_nil(debug.gethook())
		-- and then also retuns function that executes assert.not_nil(debug.gethook())
		mt_not_nil.test()
		-- Debug hooks should stay enabled afterwards
		assert.not_nil(debug.gethook())
	end)

	it("stays disabled for __index after pop", function()
		hooks:pop()
		-- mt_is_nil.__index first executes assert.is_nil(debug.gethook())
		-- and then also retuns function that executes assert.is_nil(debug.gethook())
		mt_is_nil.test()
		-- Debug hooks should stay disabled afterwards
		assert.is_nil(debug.gethook())
	end)

	it("stays enabled for __index within call", function()
		hooks:call(function(arg)
			mt_not_nil.test()
		end)
	end)

	it("is enabled for __index within call after pop", function()
		hooks:pop()
		hooks:call(function(arg)
			mt_not_nil.test()
		end)
	end)

	it("is enabled for __index within call after nested pop", function()
		hooks:pop()
		hooks:pop()
		hooks:call(function(arg)
			mt_not_nil.test()
		end)
	end)

end)
