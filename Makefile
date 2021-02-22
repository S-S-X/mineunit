install:
ifdef INSTALL
	@echo --- install mineunit
	@echo LUADIR: "$(LUADIR)"
	mkdir -p $(LUADIR)
	cp -a *.lua common default game $(LUADIR)
else
	@true
endif
