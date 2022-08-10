# mineunit
Minetest core / engine libraries for regression tests

![](https://byob.yarr.is/S-S-X/mineunit/coverage)

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

### Install demo spec, alternative to above `mkdir spec`
You can install demo `spec` directory containing simple tests and showing some things you can do.<br>
To install demo spec cd to your mod directory, there must be `init.lua` file and there cannot be existing `spec` directory.
* Run command: `$ mineunit --demo`

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

### Using Minetest classes and methods

API is not complete yet but issues are getting fixed and more functinoality have been added, create issue if you find problems
* To set node metadata, simply call `minetest.get_meta(pos):set_string("hello", "world")` just like you would do in your mod.
* To create ItemStack, simply call `ItemStack("default:cobble 99")` just like you would do in your mod.
* Any other things similar way, just like you'd do it in Minetest mods.

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

### Useful Mineunit API functions

Mineunit itself comes with some additional functionality to allow controlled test execution:

| Function                                                        | Description
| --------------------------------------------------------------- | ----------------------------------------------------
| `mineunit:set_modpath(name, path)`                              | Set modpath for named mod, `minetest.get_modpath(name)` will then report this path.
| `mineunit:set_current_modname(name)`                            | Temporarily switch current mod name to another to test code that checks current mod name.
| `mineunit:restore_current_modname()`                            | Restore original modname after changing it using `mineunit:set_current_modname(name)`.
| `mineunit:execute_globalstep(dtime)`                            | Execute Minetest globalstep: will trigger registered globalsteps, nodetimers, minetest.after and similar callbacks.
| `mineunit:mods_loaded()`                                        | Execute functions registered with `minetest.register_on_mods_loaded(func)`.
| `mineunit:execute_shutdown()`                                   | Simulate server shutdown event.
| `mineunit:execute_on_joinplayer(player, options)`               | Simulate `Player` joining the game. Use `options` table for details like `address` and `lastlogin`.
| `mineunit:execute_on_leaveplayer(player, timeout)`              | Simulate `Player` leaving the game.
| `mineunit:execute_on_chat_message(sender, message)`             | Simulate `Player` sending chat message.
| `mineunit:execute_modchannel_message(channel, sender, message)` | Modchannel message handlers.
| `mineunit:execute_modchannel_signal(channel, signal)`           | Modchannel message handlers.
| `mineunit:protect(pos, name_or_player)`                         | Add position to protection list to simlate protection without loading protection mods.
| `mineunit:get_players()`                                        | Get all registered players, when using auth module it will also return players that have not joined the game.
| `mineunit:has_module(name)`                                     | Tell if Mineunit module has been loaded.
| `mineunit:config(key)`                                          | Read Mineunit configuration values.
| `mineunit:debug(...)`                                           | Prints to console if `verbose` option is higher than 3.
| `mineunit:info(...)`                                            | Prints to console if `verbose` option is higher than 2.
| `mineunit:warning(...)`                                         | Prints to console if `verbose` option is higher than 1.
| `mineunit:error(...)`                                           | Prints to console if `verbose` option is higher than 0.
| `print(...)`                                                    | Prints to console if `print` option is not disabled.
| `mineunit:destroy_nodetimer(pos)`                               | Use Minetest counterpart instead
| `mineunit:get_modpath(name)`                                    | Use Minetest counterpart instead
| `mineunit:get_current_modname()`                                | Use Minetest counterpart instead
| `mineunit:get_worldpath()`                                      | Use Minetest counterpart instead
| `mineunit:register_on_mods_loaded(func)`                        | Use Minetest counterpart instead
| `mineunit.export_object(obj, def)`                              | Internal use
| `mineunit.deep_merge(data, target, defaults)`                   | Internal use
| `mineunit.registered_craft_recipe(output, method)`              | Internal use

Mineunit modules will add some functionality like some simple player actions simulation and such.

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
| auth                | Provides authentication API.
| entity              | Provides SAO entity API.
| common/chatcommands | Minetest engine library.
| game/chat           | Minetest engine library.
| assert              | Provides custom assertions like `assert.isPlayer(thing)` and `assert.is_ItemStack(thing)`.

### Command line arguments

```
Usage:
	mineunit [-c|--coverage] [-v|--verbose] [-q|--quiet] [-x|--exclude <pattern>]
	  [--engine-version <version>] [--fetch-core <version>] [--core-root <path>]

Options:
	-h, --help      Display this help message.

	-c, --coverage  Execute luacov test coverage analysis.
	-r, --report    Build report after successful coverage analysis.
	                Currently cannot be combined with --coverage
	-x|--exclude <pattern>
	                Exclude source file patterns from test coverage analysis.
	                Can be repeated for multiple patterns.

	--demo          Install demo tests to current directory.
	                Good way to learn Mineunit or initialize tests for project.

	--core-root <path>
	                Root directory for core libraries, defaults to install path.
	--engine-version <tag>
	                Use core engine libraries from git tag version.
	--fetch-core <tag>
	                Download core engine libraries for tag.
	                This is simple wrapper around `git clone`.

	-v|--verbose    Be verbose, prints more useless crap to console.
	-q|--quiet      Be quiet, most of time keeps your console fairly clean.

Configuration files (in order):
	/etc/mineunit/mineunit.conf
	$HOME/.mineunit.conf
	$HOME/.mineunit/mineunit.conf
	./spec/mineunit.conf
```

Configuration files are checked and merged in order and last configuration entry will take effect.
For example core_root in project configuration will override core_root in user configuration.

Command line arguments will override all configuration file entries except for luacov excludes which will be merged.
Table values (other than luacov excludes) are only supported in project configuration file.

### Known projects using mineunit

See following projects for more examples on how to use mineunit and what you can do with it

#### Technic Plus: simple, clean and straightforward tests.
* Network tests https://github.com/mt-mods/technic/tree/master/technic/spec
* CNC tests https://github.com/mt-mods/technic/tree/master/technic_cnc/spec
* GitHub workflow https://github.com/mt-mods/technic/blob/master/.github/workflows/mineunit.yml

#### Metatool: complex test setup. Mineunit development began here.
* Metatool API tests https://github.com/S-S-X/metatool/tree/master/metatool/spec
* Sharetool tests https://github.com/S-S-X/metatool/tree/master/sharetool/spec
* Containertool tests https://github.com/S-S-X/metatool/tree/master/containertool/spec
* Tubetool tests https://github.com/S-S-X/metatool/tree/master/tubetool/spec
* GitHub workflow https://github.com/S-S-X/metatool/blob/master/.github/workflows/mineunit.yml

#### Other mods
* QoS https://github.com/S-S-X/qos/tree/master/spec
* Machine_parts https://github.com/mt-mods/machine_parts/tree/master/spec
* Beerchat (chat commands and message delivery) https://github.com/minetest-beerchat/beerchat/tree/master/spec
* Mapblock_lib https://github.com/BuckarooBanzay/mapblock_lib/tree/master/spec
