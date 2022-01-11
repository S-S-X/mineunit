package = "mineunit"
version = "scm-4"
source = {
	url = "git+https://github.com/S-S-X/mineunit.git",
}
description = {
	summary = "Regression test framework for Minetest mods",
	homepage = "https://github.com/S-S-X/mineunit",
	license = "MIT"
}
dependencies = {
	"lua >= 5.1",
	"busted >= 2.0",
	"luacov >= 0.14"
}
build = {
	type = 'make',
	build_variables = {
		INSTALL="1",
		BINDIR="$(BINDIR)",
		LUADIR="$(LUADIR)/mineunit",
		CFLAGS="$(CFLAGS)"
	},
}
