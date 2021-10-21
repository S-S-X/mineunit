# mineunit
Minetest core / engine libraries for regression tests

![mineunit](https://mineunit-badges.000webhostapp.com/mt-mods/mineunit/coverage)

Probably will not currently work with Windows so unless you want to help fixing things use Linux or similar OS.

Github integration is available to automatically execute tests when new code is pushed: https://github.com/marketplace/actions/mineunit-runner

### How to use mineunit

Install mineunit and create spec directory for tests:
```bash
$ luarocks install --server=https://luarocks.org/dev --local mineunit
$ cd ~/.minetest/mods/my_minetest_mod
$ mkdir spec
```

* Add tests by creating test files inside `spec` directory.
* File names should match pattern `*_spec.lua`, for example `mymod_spec.lua`.
* See examples below for possible spec file contents.

### Define world for tests

World can be replaced by calling `world.layout` with table containing nodes, this will reset previously created world layout.
You can also add more nodes without resetting previously added world layout by calling `world.add_layout` instead of `world.layout`.
```lua
world.layout({
	{{x=0,y=0,z=0}, "default:cobble"},
	{{x=0,y=1,z=0}, "default:cobble"},
	{{x=0,y=2,z=0}, "default:cobble"},
	{{x=0,y=3,z=0}, "default:cobble"},
})
```
Individual nodes can be added and removed with `world.set_node`:
```lua
world.set_node({x=0,y=0,z=0}, {name="default:stone", param2=0})
```
to remove node from world just set node to `nil`:
```lua
world.set_node({x=0,y=0,z=0}, nil)
```
to remove everything from world:
```lua
world.clear()
```

### Metadata

https://github.com/mt-mods/mineunit/issues/2
To set node metadata, simply call `minetest.get_meta(pos):set_string("hello", "world")` just like you would do in your mod.

### ItemStack

https://github.com/mt-mods/mineunit/issues/1
To create ItemStack, simply call `ItemStack("default:cobble 99")` just like you would do in your mod.

### Example mymod/spec/mymod_spec.lua file

Following comes with a lot of useless stuff just to show how to use some mineunit functionality

```lua
-- Load and configure mineunit
require("mineunit")

-- Load some mineunit modules
mineunit("core")
mineunit("player")
mineunit("protection")
mineunit("default/functions")

-- Load some fixtures from spec/fixtures/nodes.lua for tests
-- Skip this if your tests do not need fixtures
fixture("nodes")

-- Load some mymod source files, you wanted to test these right?
-- This will execute init.lua in current directory
sourcefile("init")

-- Maybe we need actual world for test?
-- If world is larger or reused by multiple test specs it might be good
-- idea to put this into spec/fixtures/world.lua and load using fixture("world")
world.layout({
	{{x=0,y=1,z=0}, "mymod:special_dirt"},
	{{x=0,y=0,z=0}, "mymod:special_dirt"},
	{{x=1,y=0,z=0}, "mymod:special_dirt"},
	{{x=0,y=0,z=1}, "mymod:special_dirt"},
	{{x=1,y=0,z=1}, "mymod:special_dirt"},
})

-- Protect some nodes, this will affect outcome of minetest.is_protected calls
mineunit:protect({x=0,y=1,z=0}, "Sam")

-- Create few players
local player1 = Player("Sam", {interact=1})
local player2 = Player("SX", {interact=1})

-- Define tests for busted
describe("My test world", function()

	it("contains special_dirt", function()
		local node = minetest.get_node({x=0,y=0,z=0})
		assert.not_nil(node)
		assert.equals("mymod:special_dirt", node.name)
	end)

	it("allows Sam to dig dirt at y 1", function()
		assert.equals(false, minetest.is_protected({x=0,y=1,z=0}, player1:get_player_name()))
	end)

	it("protects dirt at y 1 from SX", function()
		assert.equals(true, minetest.is_protected({x=0,y=1,z=0}, player2:get_player_name()))
	end)

end)
```

### Important Mineunit API functions

| Function                             | Description
| ------------------------------------ | ---------------------
| `mineunit:debug(...)`                | Prints to console if `verbose` option is higher than 3. Adds `D:` before every printed message.
| `mineunit:info(...)`                 | Prints to console if `verbose` option is higher than 2. Adds `I:` before every printed message.
| `mineunit:warning(...)`              | Prints to console if `verbose` option is higher than 1. Adds `W:` before every printed message.
| `mineunit:error(...)`                | Prints to console if `verbose` option is higher than 0. Adds `E:` before every printed message.
| `print(...)`                         | Prints to console if `print` option is not disabled.
| `mineunit:set_modpath(name, path)`   | Set path of mod, affects return value of `minetest.get_modpath(name)`
| `mineunit:set_current_modname(name)` | Change modname returned by `minetest.get_current_modname()`
| `mineunit:restore_current_modname()` | Restore original modname after changing it using `mineunit:set_current_modname(name)`
| `mineunit:mods_loaded()`             | Execute functions registered with `minetest.register_on_mods_loaded(func)`

### Mineunit modules

#### core module

`mineunit("core")` will load multiple modules and setups basic environment for simple tests, modules that will be loaded automatically with `core` module:

| Module name         | Description
| ------------------- | -------------------
| world               | Provides `world` namespace to allow node manipulation in test world.
| settings            | Provides `Settings` class. `core` module will also load minetest configuration file from fixtures directory if present.
| metadata            | Provides metadata and inventory manipulation for tests.
| itemstack           | Provides `ItemStack` class.
| game/constants      | Minetest engine library.
| game/item           | Minetest engine library.
| game/misc           | Minetest engine library.
| game/register       | Minetest engine library.
| game/privileges     | Minetest engine library.
| common/misc_helpers | Minetest engine library.
| common/vector       | Minetest engine library.
| common/serialize    | Minetest engine library.
| common/fs           | Minetest engine library.

It is recommended to always load `core` module instead of selecting individual automatically loaded modules.

#### Additional modules

| Module name         | Description
| ------------------- | -------------------
| http                | Provides functionality for testing mods that request HTTP API using `minetest.request_http_api()`.
| nodetimer           | Provides nodetimer functionality.
| player              | Provides `Player` class, privilege functions and formspec functions. Loads `metadata` as dependency.
| protection          | Provides simple node protection API to simulate `minetest.is_protected(pos)` behavior.
| server              | Provides functionality for globalstep, player, modchannel and chat. Loads `nodetimer`, `common/chatcommands` and `game/chat` as dependencies.
| voxelmanip          | Provides `VoxelManip` class.
| common/chatcommands | Minetest engine library.
| game/chat           | Minetest engine library.

### Known projects using mineunit

See following projects for more examples on how to use mineunit and what you can do with it

#### Technic Plus: simple, clean and straightforward tests.
* Network tests https://github.com/mt-mods/technic/tree/master/technic/spec
* GitHub workflow https://github.com/mt-mods/technic/blob/master/.github/workflows/busted.yml

#### Metatool: complex test setup. Mineunit development began here.
* Mineunit and global fixtures https://github.com/S-S-X/metatool/tree/master/spec
* Metatool API tests https://github.com/S-S-X/metatool/tree/master/metatool/spec
* Container tool behavior tests https://github.com/S-S-X/metatool/tree/master/containertool/spec
* GitHub workflow https://github.com/S-S-X/metatool/blob/master/.github/workflows/busted.yml
