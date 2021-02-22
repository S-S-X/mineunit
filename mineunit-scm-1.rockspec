package = "mineunit"
version = "scm-1"
source = {
	url = "git://github.com/mt-mods/mineunit.git",
}
description = {
	summary = "Regression test framework for Minetest mods",
	homepage = "https://github.com/mt-mods/mineunit",
	license = "MIT"
}
dependencies = {
	"lua >= 5.1",
	"busted >= 2.0"
}
build = {
	type = 'make',
	build_variables = {
		INSTALL="1",
		LUADIR="$(LUADIR)/mineunit",
		CFLAGS="$(CFLAGS)"
	},
}
