
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

end)
