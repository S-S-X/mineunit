return function(DEPRECATED)
	--luacheck:push globals mineunit
	function mineunit.registered_craft_recipe(output, method)
		DEPRECATED("Using deprecated function 'mineunit.registered_craft_recipe'")
		return mineunit('craftmanager'):registered_craft_recipe(output, method)
	end
	--luacheck:pop

	--luacheck:push globals timeit
	function timeit(count, func, ...)
		DEPRECATED("Using deprecated global function 'timeit', don't use it.")
		local t1 = os.clock() * 1000
		for i=0,count do
			func(...)
		end
		local diff = (os.clock() * 1000) - t1
		local info = debug.getinfo(func,'S')
		mineunit:info(("\nTimeit: %s:%d took %d ticks"):format(info.short_src, info.linedefined, diff))
		return diff, info
	end
	--luacheck:pop

	--luacheck:push globals count
	function count(...)
		DEPRECATED("Using deprecated global function 'count', use 'mineunit.utils.count' instead.")
		return mineunit.utils.count(...)
	end
	--luacheck:pop
end