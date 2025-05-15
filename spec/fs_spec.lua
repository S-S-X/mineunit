
-- For self tests package path must be set in a way that makes package loaders search current directory first
package.path = "./?.lua;../?/init.lua;../?.lua;" --.. package.path

describe("Mineunit filesystem API", function()

	require("mineunit")
	mineunit:config_set("silence_global_export_overrides", true)
	mineunit("fs")

	it("has required functions", function()
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
		core.safe_file_write("test1.txt", "Hello Mineunit!\nHello safe_file_write!")
	end)

	it("lists files", function()
		local things = core.get_dir_list(".", nil)
		assert.array(things).has.no.holes()
		assert.equals(2, #things)
		assert.array({ "test1", "test1.txt" }).has(things)
	end)

	it("io reads file created by core.safe_file_write", function()
		local file = io.open("test1.txt", "r")
		assert.equals("file", io.type(file))
		assert.equals("Hello Mineunit!", file:read())
		assert.equals("Hello safe_file_write!", file:read())
		file:close()
	end)

	it("io writes file", function()
		local file = io.open("io_test1.txt", "w")
		-- TODO: File should have been created now, new test case for this
		assert.equals("file", io.type(file))
		file:write("Hello Mineunit!", "\n", "Hello io.write!")
		file:close()
	end)

	it("io reads file created by io.write", function()
		local file = io.open("io_test1.txt", "r")
		assert.equals("file", io.type(file))
		assert.equals("Hello Mineunit!", file:read())
		assert.equals("Hello io.write!", file:read())
		file:close()
	end)

	it("io iterates lines created by io.write", function()
		local file = io.open("io_test1.txt", "r")
		assert.equals("file", io.type(file))
		local lines = file:lines()
		assert.equals("Hello Mineunit!", lines())
		assert.equals("Hello io.write!", lines())
		file:close()
	end)

end)

describe("Mineunit fake io", function()

	require("mineunit")
	mineunit:config_set("silence_global_export_overrides", true)
	mineunit("fs")

	do -- could also consider before_each(function()
		-- Fake fs storage reset and validate
		mineunit:reset_fs()
		local filelist = core.get_dir_list(".", nil)
		assert.is_indexed(filelist)
		assert.equals(0, #filelist)
		core.safe_file_write("io.open r with file", "Hello Mineunit\nI/O!")
		core.safe_file_write("io.open a with file", "Hello Mineunit\nI/O!")
		core.safe_file_write("io.open w with file", "Hello Mineunit\nI/O!")
		core.safe_file_write("io.open r with empty file", "")
		assert.equals(4, #core.get_dir_list(".", nil))
	end -- )

	-- Test wrapper to reduce typo errors in tests
	local function test(name, mode, spec, fn)
		it(name.."("..mode..") "..spec, function()
			fn(io.open(table.concat({name, mode, spec}, " "), mode))
		end)
	end

	describe("read(*a)", function()

		test("io.open", "r", "without file", function(file)
			assert.is_nil(file)
		end)

		test("io.open", "r", "with file", function(file)
			assert.not_nil(file)
			assert.equals("Hello Mineunit\nI/O!", file:read("*a"))
		end)

		test("io.open", "r", "with empty file", function(file)
			assert.not_nil(file)
			local a, b = file:read("*a")
			-- Output is nil without errors
			assert.equals("", a)
			assert.is_nil(b)
		end)

		test("io.open", "a", "without file", function(file)
			assert.not_nil(file)
			local a, b = file:read("*a")
			-- Output is nil with error
			assert.is_nil(a)
			assert.is_string(b)
		end)

		test("io.open", "a", "with file", function(file)
			assert.not_nil(file)
			local a, b = file:read("*a")
			-- Output is nil with error
			assert.is_nil(a)
			assert.is_string(b)
		end)

		test("io.open", "w", "without file", function(file)
			assert.not_nil(file)
			local a, b = file:read("*a")
			-- Output is nil with error
			assert.is_nil(a)
			assert.is_string(b)
		end)

		test("io.open", "w", "with file", function(file)
			assert.not_nil(file)
			local a, b = file:read("*a")
			-- Output is nil with error
			assert.is_nil(a)
			assert.is_string(b)
		end)

	end)

	describe("read(*l)", function()

		test("io.open", "r", "without file", function(file)
			assert.is_nil(file)
		end)

		test("io.open", "r", "with file", function(file)
			assert.not_nil(file)
			assert.equals("Hello Mineunit", file:read("*l"))
			assert.equals("I/O!", file:read("*l"))
		end)

		test("io.open", "r", "with empty file", function(file)
			assert.not_nil(file)
			local a, b = file:read("*l")
			-- Output is nil without errors
			assert.is_nil(a)
			assert.is_nil(b)
		end)

		test("io.open", "a", "without file", function(file)
			assert.not_nil(file)
			local a, b = file:read("*l")
			-- Output is nil with error
			assert.is_nil(a)
			assert.is_string(b)
		end)

		test("io.open", "a", "with file", function(file)
			assert.not_nil(file)
			local a, b = file:read("*l")
			-- Output is nil with error
			assert.is_nil(a)
			assert.is_string(b)
		end)

		test("io.open", "w", "without file", function(file)
			assert.not_nil(file)
			local a, b = file:read("*l")
			-- Output is nil with error
			assert.is_nil(a)
			assert.is_string(b)
		end)

		test("io.open", "w", "with file", function(file)
			assert.not_nil(file)
			local a, b = file:read("*l")
			-- Output is nil with error
			assert.is_nil(a)
			assert.is_string(b)
		end)

	end)

	describe("interface", function()

		it("has no internal properties", function()
			local file = io.open("_1", "w")
			assert.not_nil(file)
			pending("Internal properties of File not hidden")
			assert.is_nil(file._path)
		end)

		it("does not allow writing new keys", function()
			local file = io.open("_2", "w")
			assert.not_nil(file)
			assert.has_error(function()
				file.newkey = true
			end)
		end)

	end)

end)