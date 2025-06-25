
-- For self tests package path must be set in a way that makes package loaders search current directory first
package.path = "./?.lua;../?/init.lua;../?.lua;" --.. package.path

require("mineunit")
mineunit:config_set("silence_global_export_overrides", true)
mineunit("common/misc_helpers")
local depends_on = fixture("test_depends_on")

describe("Mineunit filesystem API", function()

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

	describe("core functions", function()

		depends_on("Mineunit filesystem API has required functions")

		it("creates directory", function()
			core.mkdir("test1")
			local things = core.get_dir_list(".", true)
			assert.in_array("test1", things)
		end)

		it("writes file", function()
			core.safe_file_write("test1.txt", "Hello Mineunit!\nHello safe_file_write!")
			local things = core.get_dir_list(".", false)
			assert.in_array("test1.txt", things)
		end)

		it("lists files and directories", function()
			depends_on("Mineunit filesystem API core functions creates directory")
			depends_on("Mineunit filesystem API core functions writes file")
			local things = core.get_dir_list(".", nil)
			assert.array(things).has.no.holes()
			assert.equals(2, #things)
			assert.in_array("test1", things)
			assert.in_array("test1.txt", things)
		end)

		it("io reads file created by core.safe_file_write", function()
			depends_on("Mineunit filesystem API core functions writes file")
			local file = io.open("test1.txt", "r")
			assert.equals("file", io.type(file))
			assert.equals("Hello Mineunit!", file:read())
			assert.equals("Hello safe_file_write!", file:read())
			file:close()
		end)

	end)

	describe("io functions", function()

		depends_on("Mineunit filesystem API core functions writes file")

		it("writes file", function()
			local file = io.open("io_test1.txt", "w")
			assert.equals("file", io.type(file))
			file:write("Hello Mineunit!", "\n", "Hello io.write!")
			file:close()
		end)

		it("reads file created by io.write", function()
			depends_on("Mineunit filesystem API io functions writes file")
			local file = io.open("io_test1.txt", "r")
			assert.equals("file", io.type(file))
			assert.equals("Hello Mineunit!", file:read())
			assert.equals("Hello io.write!", file:read())
			file:close()
		end)

		it("iterates lines created by io.write", function()
			local file = io.open("io_test1.txt", "r")
			assert.equals("file", io.type(file))
			local lines = file:lines()
			assert.equals("Hello Mineunit!", lines())
			assert.equals("Hello io.write!", lines())
			file:close()
		end)

		it("creates file", function()
			io.open("io_test2.txt", "w"):close()
			local list = core.get_dir_list(".", false)
			assert.in_array("io_test2.txt", list)
		end)

	end)

end)

describe("mineunit:fs_copy", function()

	mineunit:config_set("silence_global_export_overrides", true)
	mineunit("fs")

	before_each(function()
		mineunit:fs_reset()
	end)

	it("does single copy", function()
		mineunit:fs_copy(mineunit:get_worldpath() .. "/testfile.bin", "testfile.bin")
		local expected = {
			["testfile.bin"] = "\1\128\0\0\173\255\10\66\9\8\7\6\5"
		}
		expected["."] = expected
		local container = mineunit:fs_raw():get(".")
		assert.same(expected, container)
	end)

	it("does recursive copy", function()
		mineunit:fs_copy(mineunit:get_worldpath() .. "/rec", "rec")
		local expected = {
			["rec"] = {
				["rec.file"] = "1"
			},
			["rec/urs"] = {
				["urs.file"] = "2"
			},
			["rec/urs/ive"] = {
				["ive.file"] = "3"
			}
		}
		expected["."] = expected
		expected["rec"]["."] = expected["rec"]
		expected["rec/urs"]["."] = expected["rec/urs"]
		expected["rec/urs/ive"]["."] = expected["rec/urs/ive"]
		local container = mineunit:fs_raw():get(".")
		assert.same(expected, container)
	end)

end)

describe("Mineunit fake os", function()

	depends_on("Mineunit filesystem API core functions creates directory")
	depends_on("mineunit:fs_copy does recursive copy")

	mineunit:config_set("silence_global_export_overrides", true)
	mineunit("fs")

	before_each(function() -- Initialize fake filesystem for tests
		mineunit:fs_reset()
		mineunit:fs_copy(mineunit:get_worldpath() .. "/rec", ".")
		core.mkdir("urs/empty")
	end)

	it("remove() root", function()
		local original = (function()
			local container = mineunit:fs_raw():get(".")
			return table.copy(container)
		end)()
		assert.is_hashed(original)
		assert.same({nil, "ENOENT"}, {os.remove(".")})
		local afterward = mineunit:fs_raw():get(".")
		assert.same(original, afterward)
	end)

	it("remove() file", function()
		assert.equals(1, #core.get_dir_list(".", false))
		assert(os.remove("rec.file"))
		assert.equals(0, #core.get_dir_list(".", false))
	end)

	it("remove() empty directory", function()
		local dirs = #core.get_dir_list(".", true)
		assert(os.remove("urs/empty"))
		assert.equals(dirs - 1, #core.get_dir_list(".", true))
	end)

	it("remove() non empty directory", function()
		local dirs = #core.get_dir_list(".", true)
		assert(not os.remove("urs"))
		assert.equals(dirs, #core.get_dir_list(".", true))
	end)

	it("rename() file at root", function()
		-- Validate fs state
		local list_before = core.get_dir_list(".", false)
		assert.in_array("rec.file", list_before)
		assert.not_in_array("other.file", list_before)
		-- Rename file
		local success, message = os.rename("rec.file", "other.file")
		assert.is_true(success)
		assert.is_nil(message)
		-- Check results
		local list_after = core.get_dir_list(".", false)
		assert.not_in_array("rec.file", list_after)
		assert.in_array("other.file", list_after)
	end)

	it("rename() file at subdir", function()
		-- Validate fs state
		local list_before = core.get_dir_list("urs/ive", false)
		assert.in_array("ive.file", list_before)
		assert.not_in_array("other.file", list_before)
		-- Rename file
		local success, message = os.rename("urs/ive/ive.file", "urs/ive/other.file")
		assert.is_true(success)
		assert.is_nil(message)
		-- Check results
		local list_after = core.get_dir_list("urs/ive", false)
		assert.not_in_array("ive.file", list_after)
		assert.in_array("other.file", list_after)
	end)

	it("rename() file between subdirs", function()
		-- Validate fs state
		assert.equals(0, #core.get_dir_list("urs/empty", false))
		local list_before = core.get_dir_list("urs/ive", false)
		assert.in_array("ive.file", list_before)
		assert.not_in_array("other.file", list_before)
		-- Rename file
		local success, message = os.rename("urs/ive/ive.file", "urs/empty/other.file")
		assert.is_true(success)
		assert.is_nil(message)
		-- Check results
		assert.equals(0, #core.get_dir_list("urs/ive", false))
		local list_after = core.get_dir_list("urs/empty", false)
		assert.not_in_array("ive.file", list_after)
		assert.in_array("other.file", list_after)
	end)

	it("rename() first argument nil", function()
		assert.error(function()
			os.rename(nil, "other.file")
		end)
	end)

	it("rename() second argument nil", function()
		assert.error(function()
			os.rename("rec.file", nil)
		end)
	end)

	it("rename() missing source file", function()
		local success, message = os.rename("other.file", "rec.file")
		assert.is_nil(success)
		assert.is_string(message)
	end)

	it("rename() dir over file", function()
		local success, message = os.rename("urs", "rec.file")
		assert.is_nil(success)
		assert.is_string(message)
	end)

	it("rename() file over dir", function()
		local success, message = os.rename("rec.file", "urs")
		assert.is_nil(success)
		assert.is_string(message)
	end)

end)

describe("Mineunit fake io", function()

	depends_on("mineunit:fs_copy does single copy")

	mineunit:config_set("silence_global_export_overrides", true)
	mineunit("fs")

	setup(function() -- Initialize fake filesystem for tests
		-- Fake fs storage reset and validate
		mineunit:fs_reset()
		local filelist = core.get_dir_list(".", nil)
		assert.is_indexed(filelist)
		assert.equals(0, #filelist)
		-- Create some test files
		core.safe_file_write("io.open r with file", "Hello Mineunit\nI/O!")
		core.safe_file_write("io.open a with file", "Hello Mineunit\nI/O!")
		core.safe_file_write("io.open w with file", "Hello Mineunit\nI/O!")
		core.safe_file_write("io.open r with empty file", "")
		-- b
		core.safe_file_write("io.open rb with file", "Hello Mineunit\nI/O!")
		core.safe_file_write("io.open ab with file", "Hello Mineunit\nI/O!")
		core.safe_file_write("io.open wb with file", "Hello Mineunit\nI/O!")
		core.safe_file_write("io.open rb with empty file", "")
		-- +
		core.safe_file_write("io.open r+ with file", "Hello Mineunit\nI/O!")
		core.safe_file_write("io.open a+ with file", "Hello Mineunit\nI/O!")
		core.safe_file_write("io.open w+ with file", "Hello Mineunit\nI/O!")
		core.safe_file_write("io.open r+ with empty file", "")
		-- b+
		core.safe_file_write("io.open rb+ with file", "Hello Mineunit\nI/O!")
		core.safe_file_write("io.open ab+ with file", "Hello Mineunit\nI/O!")
		core.safe_file_write("io.open wb+ with file", "Hello Mineunit\nI/O!")
		core.safe_file_write("io.open rb+ with empty file", "")
		-- copy files
		mineunit:fs_copy(mineunit:get_worldpath() .. "/testfile.bin", "testfile.bin") -- 01800000adff0a420908070605
		-- Validate file count
		assert.equals(17, #core.get_dir_list(".", nil))
	end)

	describe("io.open binary", function()

		it("read(n) straight", function()
			local file = io.open("testfile.bin", "rb")
			assert.equals("\1", file:read(1))
			assert.equals("\128", file:read(1))
			assert.equals("\0\0", file:read(2))
			assert.equals("\173\255", file:read(2))
			assert.equals("\10\66\9", file:read(3))
			assert.equals("\8\7\6\5", file:read(4))
			assert.is_nil(file:read(1))
			file:close()
		end)

		it("read(n) with seek", function()
			local file = io.open("testfile.bin", "rb")
			file:seek("set", 1)
			assert.equals("\128", file:read(1))
			file:seek("cur", 1)
			assert.equals("\0\173\255", file:read(3))
			file:seek("cur", -1)
			assert.equals("\255\10\66\9", file:read(4))
			file:seek("set", 0)
			assert.equals("\1", file:read(1))
			file:seek("end", 0)
			assert.is_nil(file:read(1))
			file:close()
		end)

		it("read(*l) last byte", function()
			local file = io.open("testfile.bin", "rb")
			file:seek("end", -1)
			assert.equals("\5", file:read("*l"))
			assert.is_nil(file:read("*l"))
			file:close()
		end)

		it("read(*l) end of file", function()
			local file = io.open("testfile.bin", "rb")
			file:seek("end")
			assert.is_nil(file:read("*l"))
			file:close()
		end)

		it("read(n|*l) with seek", function()
			local file = io.open("testfile.bin", "rb")
			file:seek("cur", 1)
			assert.equals("\128\0", file:read(2))
			assert.equals("\0\173\255", file:read("*l"))
			assert.equals("\66\9\8\7\6\5", file:read("*l"))
			file:seek("set", 0)
			assert.equals("\1\128\0\0\173\255", file:read("*l"))
			assert.equals("\66", file:read(1))
			assert.equals("\9\8\7\6\5", file:read("*l"))
			assert.is_nil(file:read(1))
			file:close()
		end)

	end)

	-- Test wrapper to reduce typo errors in tests
	local function test(name, mode, spec, fn)
		it(name.."("..mode..") "..spec, function()
			fn(io.open(table.concat({name, mode, spec}, " "), mode))
		end)
	end

	describe("io.open failures", function()

		test("io.open", "r", "without file", function(file)
			assert.is_nil(file)
		end)

		test("io.open", "rb", "without file", function(file)
			assert.is_nil(file)
		end)

	end)

	describe("read(n)", function()

		test("io.open", "rb", "with file", function(file)
			assert.not_nil(file)
			assert.equals("Hel", file:read(3))
			assert.equals("lo ", file:read(3))
			file:seek("set", 6)
			assert.equals("Min", file:read(3))
		end)

		test("io.open", "rb", "with empty file", function(file)
			assert.not_nil(file)
			local a, b = file:read(3)
			-- Output is nil without errors
			assert.is_nil(a)
			assert.is_nil(b)
		end)

		test("io.open", "ab", "without file", function(file)
			assert.not_nil(file)
			local a, b = file:read(3)
			-- Output is nil with error
			assert.is_nil(a)
			assert.is_string(b)
		end)

		test("io.open", "ab", "with file", function(file)
			assert.not_nil(file)
			local a, b = file:read(3)
			-- Output is nil with error
			assert.is_nil(a)
			assert.is_string(b)
		end)

		test("io.open", "wb", "without file", function(file)
			assert.not_nil(file)
			local a, b = file:read(3)
			-- Output is nil with error
			assert.is_nil(a)
			assert.is_string(b)
		end)

		test("io.open", "wb", "with file", function(file)
			assert.not_nil(file)
			local a, b = file:read(3)
			-- Output is nil with error
			assert.is_nil(a)
			assert.is_string(b)
		end)

	end)

	describe("read(*a)", function()

		depends_on("Mineunit filesystem API io functions reads file created by io.write")

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

		test("io.open", "r", "with file", function(file)
			assert.not_nil(file)
			assert.equals("Hello Mineunit", file:read("*l"))
			assert.equals("I/O!", file:read("*l"))
			assert.is_nil(file:read("*l"))
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

	describe("write() fails", function()

		test("io.open", "r", "with file", function(file)
			assert.not_nil(file)
			local content = file:read("*a")
			local a, b = file:write("!")
			-- Output is nil with error, file contents did not change
			assert.is_nil(a)
			assert.is_string(b)
			file:seek("set", 0)
			assert.equals(content, file:read("*a"))
		end)

		test("io.open", "rb", "with file", function(file)
			assert.not_nil(file)
			local content = file:read("*a")
			local a, b = file:write("!")
			-- Output is nil with error, file contents did not change
			assert.is_nil(a)
			assert.is_string(b)
			file:seek("set", 0)
			assert.equals(content, file:read("*a"))
		end)

	end)

	describe("compare read write", function()

		depends_on("Mineunit filesystem API io functions writes file")
		depends_on("Mineunit filesystem API io functions reads file created by io.write")
		depends_on("Mineunit filesystem API io functions creates file")
		depends_on("mineunit:fs_copy does single copy")

		before_each(function()
			mineunit:fs_reset()
			mineunit:fs_copy(mineunit:get_worldpath() .. "/testfile.bin", "testfile.bin")
		end)

		it("copies file read *a write all", function()
			-- Read data from file system
			local filein = io.open("testfile.bin", "rb")
			local datain = filein:read("*a")
			filein:close()
			-- Write back to file system
			local fileout = io.open("fileout.bin", "wb")
			fileout:write(datain)
			fileout:close()
			-- Validate results
			local datatest = mineunit:fs_getfile("fileout.bin")
			assert.is_string(datatest)
			assert.equals(datain, datatest)
		end)

		it("copies file read *l write all", function()
			-- Read data from file system
			local datain = (function()
				local filein = io.open("testfile.bin", "rb")
				local tmp = {}
				local line = filein:read("*l")
				while line do
					table.insert(tmp, line)
					line = filein:read("*l")
				end
				filein:close()
				return table.concat(tmp, "\n")
			end)()
			-- Write back to file system
			local fileout = io.open("fileout.bin", "wb")
			fileout:write(datain)
			fileout:close()
			-- Validate results
			local datatest = mineunit:fs_getfile("fileout.bin")
			assert.is_string(datatest)
			assert.equals(datain, datatest)
		end)

		it("copies file read 2b write all", function()
			-- Read data from file system
			local datain = (function()
				local filein = io.open("testfile.bin", "rb")
				local tmp = {}
				local word = filein:read(2)
				while word do
					table.insert(tmp, word)
					word = filein:read(2)
				end
				filein:close()
				return table.concat(tmp)
			end)()
			-- Write back to file system
			local fileout = io.open("fileout.bin", "wb")
			fileout:write(datain)
			fileout:close()
			-- Validate results
			local datatest = mineunit:fs_getfile("fileout.bin")
			assert.is_string(datatest)
			assert.equals(datain, datatest)
		end)

		it("copies file read 2b write 2b", function()
			-- Simultaneous read and write
			local filein = io.open("testfile.bin", "rb")
			local fileout = io.open("fileout.bin", "wb")
			local word = filein:read(2)
			while word do
				fileout:write(word)
				word = filein:read(2)
			end
			filein:close()
			fileout:close()
			-- Validate results
			local datain = mineunit:fs_getfile("testfile.bin")
			assert.is_string(datain)
			local dataout = mineunit:fs_getfile("fileout.bin")
			assert.is_string(dataout)
			assert.equals(datain, dataout)
		end)

		it("copies file random read/write rb+", function()
			-- Simultaneous read and write at seemingly random order skipping nulls
			local sequence = {
				{  5, 1 }, -- 5 start by writing 5th byte
				{  4, 1 }, -- 4 step backwards, should preserve byte 5
				{  0, 2 }, -- 0-1 write first 2 bytes
				{  6, 4 }, -- 6-9 non overlapping 4 byte sequence
				{  8, 4 }, -- 8-11 overlapping 4 byte sequence
				{ 12, 5 }, -- 12-16 overshoot input file size by 3 bytes
				{  0, 1 }, -- 0 TODO: this one might not be good, rewrite first byte
				--{  2, 2 }, -- two nulls never written, should still appear in output
			}
			-- Create output file
			io.open("fileout.bin", "wb"):close()
			-- Copy contents from testfile.bin
			local filein = io.open("testfile.bin", "rb")
			local fileout = io.open("fileout.bin", "rb+")
			for _, what in ipairs(sequence) do
				local at, size = unpack(what)
				filein:seek("set", at)
				fileout:seek("set", at)
				fileout:write(filein:read(size))
			end
			filein:close()
			fileout:close()
			-- Validate results
			local datain = mineunit:fs_getfile("testfile.bin")
			assert.is_string(datain)
			local dataout = mineunit:fs_getfile("fileout.bin")
			assert.is_string(dataout)
			assert.equals(datain, dataout)
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

		it("type is userdata", function()
			local file = io.open("_3", "w")
			assert.equals("userdata", type(file))
		end)

	end)

end)