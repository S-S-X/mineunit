
-- For self tests package path must be set in a way that makes package loaders search current directory first
package.path = "./?.lua;../?/init.lua;../?.lua;" --.. package.path

describe("Mineunit filesystem API", function()

	require("mineunit")
	mineunit:config_set("silence_global_export_overrides", true)
	mineunit("fs")

	it("has functions", function()
		local functions = {
			"mkdir",
			"get_dir_list",
			"safe_file_write"
		}
		for _,fn in ipairs(functions) do
			assert.equals("function", type(core[fn]), "core."..fn.." is not valid function.")
		end
	end)

	it("creates directory", function()
		core.mkdir("test1")
	end)

	it("writes file", function()
		core.safe_file_write("test1_txt", "Hello Mineunit!")
	end)

	it("lists files", function()
		local things = core.get_dir_list(".", nil)
		assert.array(things).has.no.holes()
		assert.equals(2, #things)
		assert.array({ "test1", "test1_txt" }).has(things)
	end)

end)
