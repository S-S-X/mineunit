
-- For self tests package path must be set in a way that makes package loaders search current directory first
package.path = "./?.lua;../?/init.lua;../?.lua;" --.. package.path

describe("Mineunit core", function()

	require("mineunit")
	mineunit("fs")
	mineunit("assert")

	describe("deprecation", function()

		local ANY = require("luassert.match")._
		local M = function(s) return require("luassert.match").matches(s) end

		local oldconfig = mineunit:config("deprecated")
		after_each(function()
			mineunit:config_set("deprecated", oldconfig)
		end)

		local function test_it(conf)
			return function()
				if conf then
					mineunit:config_set("deprecated", conf)
				end
				mineunit:DEPRECATED("test deprecation message")
			end
		end

		it("throws error for invalid configuration", function()
			assert.match_error(test_it("invalid"), "invalid value.*throw, error, warning, info, debug, ignore")
		end)

		it("throws error", function()
			assert.match_error(test_it(), "test deprecation message")
		end)

		for _, action in ipairs({"error", "warning", "info", "debug"}) do
			it("prints "..action, function()
				spy.on(mineunit, action)
				assert.not_error(test_it(action))
				assert.spy(mineunit[action]).called_with(ANY, M("test deprecation message"))
			end)
		end

	end)

	describe("fs", function()
		it("has functions", function()
			local functions = {
				"mkdir",
				"get_dir_list",
			}
			for _,fn in ipairs(functions) do
				assert.equals("function", type(core[fn]), "core."..fn.." is not valid function.")
			end
		end)
	end)

end)
