local pl_dir = require("pl.dir")
local pl_path = require("pl.path")

local basename = pl_path.basename

local function normpath(path)
	return pl_path.normpath(pl_path.abspath(path))
end

local fs = {}

function core.mkdir(path)
	path = normpath(path)
	assert.is_nil(fs[path])
	fs[path] = {}
end

function core.get_dir_list(path, list_dirs)
	path = normpath(path)
	local results = {}
	if list_dirs == nil then
		for name in pl_path.dir(path) do
			if name ~= "." and name ~= ".." then
				table.insert(results, name)
			end
		end
	elseif list_dirs == true then
		for _,name in ipairs(dir.getdirectories(path)) do
			table.insert(results, basename(name))
		end
	elseif list_dirs == false then
		for _,name in ipairs(dir.getfiles(path)) do
			table.insert(results, basename(name))
		end
	else
		error("Invalid list_dirs argument for core.get_dir_list(path, list_dirs)")
	end
	return results
end

function core.safe_file_write(path, content)
	path = normpath(path)
	assert.not_table(fs[path])
	assert.is_string(content)
	fs[path] = content
end