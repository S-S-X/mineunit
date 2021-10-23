
-- Simple pipeworks fixture with few no-op methods, enough for technic, metatool and jumpdrive

mineunit:set_modpath("pipeworks", "spec/fixtures")

local function noop(t)
	return setmetatable(t, {
		__call = function(self,...) return self end,
		__index = function(...) return function(...)end end,
	})
end

local pipeworks = {
	button_label = "",
	fs_helpers = {
		cycling_button = function(...) return "" end
	},
	tptube = {},
}
pipeworks.tptube = noop(pipeworks.tptube)
_G.pipeworks = noop(pipeworks)
