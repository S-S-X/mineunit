local pl = {
	dir = require 'pl.dir',
	path = require 'pl.path',
}

core.mkdir = function()
	-- no-op
	-- TODO: create directory and implement io.* functions
end

core.get_dir_list = function(path, list_dirs)
	local results = {}
	for _,name in ipairs(list_dirs and pl.dir.getdirectories(path) or pl.dir.getfiles(path)) do
		table.insert(results, pl.path.basename(name))
	end
	return results
end
