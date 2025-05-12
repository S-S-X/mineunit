-- Test dependencies, root cause filtering

local tests_at = {}
local tests_done = {}

local function depends_on(path)
	if not mineunit.utils.in_array(tests_done, path) then
		error("Failed test dependency: '"..path.."'")
	end
end

mineunit:subscribe('describe_start', function(e)
	-- add describe to stack
	tests_at[#tests_at+1] = e.name
end)

mineunit:subscribe('describe_end', function()
	-- drop describe from stack
	tests_at[#tests_at] = nil
end)

mineunit:subscribe('test_start', function(e)
	-- add test to stack
	tests_at[#tests_at+1] = e.name
end)

mineunit:subscribe('test_end', function(_, _, result)
	-- record success and drop test from stack
	if result == "success" then
		tests_done[#tests_done+1] = table.concat(tests_at, " ")
	end
	tests_at[#tests_at] = nil
end)

return depends_on