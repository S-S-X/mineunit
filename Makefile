install:
ifdef INSTALL
	@echo --- install mineunit
	@echo "BINDIR (temporary): $(BINDIR)"
	@echo "LUADIR (temporary): $(LUADIR)"
	@mkdir -p $(LUADIR)
	@cp -a *.lua common default game $(LUADIR)
	@cp -a bin/mineunit $(BINDIR)
else
	@true
endif
