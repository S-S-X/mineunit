# mineunit

Minetest and Luanti core / engine libraries for regression tests.

![](https://byob.yarr.is/S-S-X/mineunit/coverage)

Probably will not currently work with Windows so unless you want to help fixing things use Linux or similar OS.

Github integration is available to automatically execute tests when new code is pushed: https://github.com/marketplace/actions/mineunit-runner

### How to use mineunit

Recommended way is docker, it keeps both Mineunit and mod code isolated.
Docker images are also currenlty best way to get latest features.
See https://hub.docker.com/r/mineunit/mineunit for more information.

You can also install Mineunit from luarocks and create spec directory for tests:

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

Engine functions are also available if you like, for example `core.set_node(pos, node)` and `core.remove_node(pos)`.

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

#### Generic utility functions

| Function                                | Description
| --------------------------------------- | -------------------------------------------------------------------------------
| `mineunit:config(key)`                  | Read Mineunit configuration values.
| `mineunit:config_set(key, value)`       | Temporarily change Mineunit configuration values.
| `mineunit:has_module(name)`             | Tell if Mineunit module has been loaded.
| `mineunit:set_modpath(name, path)`      | Set modpath for named mod, `core.get_modpath(name)` will then report this path.
| `mineunit:set_current_modname(name)`    | Temporarily switch current mod name to another.
| `mineunit:restore_current_modname()`    | Restore original modname after changing it using `mineunit:set_current_modname(name)`.
| `mineunit:protect(pos, name_or_player)` | Add position to protection list to simlate protection without loading protection mods.
| `mineunit:get_entities()`               | Get entities added with `core.add_entity(pos, name, staticdata)`.
| `mineunit:get_players()`                | Get all registered players, when auth module is lodaded also returns offline players.

Especially `mineunit:set_modpath(name, path)`, `mineunit:set_current_modname(name)` and
`mineunit:restore_current_modname()` will come handy in case you need to load multiple mods for tests.
Technic Plus for example uses following to load `technic_worldgen` along with main mod for testing:

```lua
mineunit:set_modpath("technic_worldgen", "../technic_worldgen")
mineunit:set_current_modname("technic_worldgen")
sourcefile("../technic_worldgen/init")
mineunit:restore_current_modname()
```

Or for example while registering tools/nodes/etc. for test and fixtures following snippet might make things simpler:

```lua
local function do_register_things_for_mod(modname, callback)
	mineunit:set_modpath(modname, "spec/fixtures")
	mineunit:set_current_modname(modname)
	callback()
	mineunit:restore_current_modname()
end
```

#### Engine event simulation

| Function                                                              | Description
| --------------------------------------------------------------------- | ----------------------------------------------
| `mineunit:execute_entitystep(dtime, filter)`                          | Execute engine entitystep.
| `mineunit:execute_globalstep(dtime)`                                  | Execute engine globalstep: will trigger registered globalsteps, nodetimers, core.after and similar callbacks.
| `mineunit:execute_modchannel_message(channel, sender, message)`       | Modchannel message handlers.
| `mineunit:execute_modchannel_signal(channel, signal)`                 | Modchannel message handlers.
| `mineunit:execute_on_chat_message(sender, message)`                   | Simulate `Player` sending chat message.
| `mineunit:execute_on_joinplayer(player, options)`                     | Simulate `Player` joining the game. Use `options` table for details like `address` and `lastlogin`.
| `mineunit:execute_on_leaveplayer(player, timeout)`                    | Simulate `Player` leaving the game.
| `mineunit:execute_on_player_receive_fields(player, formname, fields)` | Simulate `Player` sending form fields.
| `mineunit:execute_shutdown()`                                         | Simulate server shutdown event.
| `mineunit:mods_loaded()`                                              | Execute functions registered with `core.register_on_mods_loaded(func)`.

With many mods it is good to run through `mineunit:mods_loaded()` and `mineunit:execute_globalstep(dtime)` either during
test set loading or soon after to make sure that all initial registrations, globalstep and timer hacks get settled.

For tests that depend oon players it can be useful to register `before_each` and `after_each` with calls to
`mineunit:execute_on_joinplayer(player, options)` and `mineunit:execute_on_leaveplayer(player, timeout)`.

#### Debug, info, warning and error formatting / output

| Function                         | Description
| -------------------------------- | -----------------------------------------------------------------------------------
| `print(...)`                     | Same as `mineunit:print(...)`. Use `io` module if you want to get around this.
| `printf(...)`                    | Sorry, this function does not exist.
| `mineunit:debug(...)`            | Prints to console if `verbose` option is higher than 3.
| `mineunit:info(...)`             | Prints to console if `verbose` option is higher than 2.
| `mineunit:warning(...)`          | Prints to console if `verbose` option is higher than 1.
| `mineunit:error(...)`            | Prints to console if `verbose` option is higher than 0.
| `mineunit:print(...)`            | Prints to console if `print` option is enabled.
| `mineunit:debugf(fmtstr, ...)`   | Like `debug` but with format string. Based on custom `string.format`, details below.
| `mineunit:infof(fmtstr, ...)`    | Like `info` but with format string. Based on custom `string.format`, details below.
| `mineunit:warningf(fmtstr, ...)` | Like `warning` but with format string. Based on custom `string.format`, details below.
| `mineunit:errorf(fmtstr, ...)`   | Like `error` but with format string. Based on custom `string.format`, details below.
| `mineunit:printf(fmtstr, ...)`   | Like `print` but with format string. Based on custom `string.format`, details below.

Format strings for above `*f` functions accept default Lua format strings with few exceptions.
String formatter `%s` can accept any argument type and will do special formatting for some common
data such as coordinates, pointed_thing and such. This holds for both Lua 5.1 and LuaJIT.
Additional `%t` formatter simply uses `dump` for everything. Besides that, same as Lua `string.format`.

#### Mostly internal / questionable / possibly unstable utility functions

| Function                                           | Description
| -------------------------------------------------- | -----------------------------------------------------------------
| `mineunit:destroy_nodetimer(pos)`                  | Use core/engine counterpart instead.
| `mineunit:get_current_modname()`                   | Use core/engine counterpart instead.
| `mineunit:get_worldpath()`                         | Use core/engine counterpart instead.
| `mineunit:get_modpath(name)`                       | Use core/engine counterpart instead.
| `mineunit:register_on_mods_loaded(func)`           | Use core/engine counterpart instead.
| `mineunit:apply_default_settings(settings)`        | Probably bad idea, possibly unstable.
| `mineunit:get_InvRef_data(thing)`                  | Direct access to invetory data `{ lists = {...}, sizes = {...}, empty = {...} }`.
| `mineunit:clear_InvRef(thing)`                     | Unstable, for now internal testing.
| `mineunit.deep_merge(data, target, defaults)`      | Internal use, might be removed in future.
| `mineunit:DEPRECATED(msg)`                         | Internal use, might be removed in future.
| `mineunit.export_object(obj, def)`                 | Internal use, possibly unstable.
| `mineunit:prepend_flush()`                         | Internal use, likely removed in future.
| `mineunit:prepend_print(s)`                        | Internal use, might be removed in future.
| `mineunit.registered_craft_recipe(output, method)` | Internal use, likely removed in future.
| `mineunit:set_timeofday(d)`                        | Set current time of day.

Mineunit modules will add some functionality like some simple player actions simulation and such.

### Mineunit modules

Unfortunately these lists are incomplete and in reality there's actually many more modules available.
Anyway, these might help a bit. And taking a look at other mods utilizing mineunit could give some ideas too.

#### core module

`mineunit("core")` will load multiple modules and setups basic environment for simple tests, modules that will be loaded automatically with `core` module:

| Module name         | Description
| ------------------- | -------------------
| world               | Provides `world` namespace to allow node manipulation in test world.
| settings            | Provides `Settings` class. `core` module will also load engine configuration file from fixtures directory if present.
| metadata            | Provides metadata and inventory manipulation for tests.
| itemstack           | Provides `ItemStack` class.
| game/constants      | Engine library.
| game/item           | Engine library.
| game/misc           | Engine library.
| game/register       | Engine library.
| game/privileges     | Engine library.
| common/misc_helpers | Engine library.
| common/vector       | Engine library.
| common/serialize    | Engine library.
| common/fs           | Engine library.

It is recommended to always load `core` module instead of selecting individual automatically loaded modules.

#### Additional modules

| Module name         | Description
| ------------------- | -------------------
| http                | Provides functionality for testing mods that request HTTP API using `core.request_http_api()`.
| nodetimer           | Provides nodetimer functionality.
| player              | Provides `Player` class, privilege functions and formspec functions. Loads `metadata` as dependency.
| protection          | Provides simple node protection API to simulate `core.is_protected(pos)` behavior.
| server              | Provides functionality for globalstep, player, modchannel and chat. Loads `nodetimer`, `common/chatcommands` and `game/chat` as dependencies.
| voxelmanip          | Provides `VoxelManip` class.
| auth                | Provides authentication API.
| entity              | Provides SAO entity API.
| common/chatcommands | Engine library.
| game/chat           | Engine library.
| assert              | Provides custom assertions, see assertions section or `--help-assert` command line argument.

### Command line arguments

```
Mineunit v0.14.0 (Lua 5.1)
Usage:
	mineunit [-c|--coverage] [-v|--verbose] [-q|--quiet] [-x|--exclude <pattern>]
		[--engine-version <version>] [--fetch-core <version>] [--core-root <path>]

Options:
	-c, --coverage  Execute luacov test coverage analysis.
	-r, --report    Build report after successful coverage analysis.
	                Currently cannot be combined with --coverage
	-x|--exclude <pattern>
	                Exclude source file path patterns from test coverage analysis.
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

	-v|--verbose    Be more verbose by printing more useless crap to console.
	                Can be repeated up to six times for even more annoying output.
	-q|--quiet      Be quiet, most of time keeps your console fairly clean.
	                Always disables regular Lua print which can make output
	                somewhat less annoying when combined with --verbose output.
	-V|--version    Display Lua and Mineunit version information.
	-h|--help       Display this cheat sheet.
	--help-assert   Display another cheat sheet, reference for special assertions.

Resources:
	Luarocks package: https://luarocks.org/modules/S-S-X/mineunit
	Issue tracker: https://github.com/S-S-X/mineunit/issues
	GitHub integration: https://github.com/marketplace/actions/mineunit-runner
	Docker images: https://hub.docker.com/r/mineunit/mineunit

Configuration files (in order):
	/etc/mineunit/mineunit.conf
	$HOME/.mineunit.conf
	$HOME/.mineunit/mineunit.conf
	./spec/mineunit.conf

License:
	MIT Expat with LGPL libraries, see LICENSE file for details.
```

Configuration files are checked and merged in order and last configuration entry will take effect.
For example core_root in project configuration will override core_root in user configuration.

Command line arguments will override all configuration file entries except for luacov excludes which will be merged.
Table values (other than luacov excludes) are only supported in project configuration file.

### Using `--coverage` and `--report` cli args

Using `--coverage` and `--report` together wont work, with `--report` cli argument mineunit
wont run any tests but just instructs luacov to format coverage data producing human readable
test coverage report called `luacov.report.out`. File is placed in current working directory.
With LuaJIT, reports generated by luacov will be broken.
Run `mineunit -V` to check used Lua version and make sure it is Lua 5.1 instead of LuaJIT.

So basically to get code coverage report you have to run `mineunit` twice, example follows:

```
$ mineunit --coverage
$ mineunit --report
```

First command executes tests, collects test coverage information and produces coverage data file.
Second command does not execute tests but reads coverage data file and formats it with source
code to produce human readable test coverage report file called `luacov.report.out`. Use any
text editor to read this file.

### Known issues

Code coverage hits and misses are very likely miscalculated if using LuaJIT, let me know in
case this gets fixed in luacov. Some preprocessing and filtering could make this a little
bit better but for now not my highest priority.

Mineunit with LuaJIT can be unpredictable.
While slower, Lua 5.1 will bring better predictability and stability.

Generally Lua 5.1 is recommended.

### Known projects using mineunit

See following projects for more examples on how to use mineunit and what you can do with it

#### Technic Plus: large test sets for networks, tools, machines, nodes, custom placement and more.
* Technic tests https://github.com/mt-mods/technic/tree/master/technic/spec
* CNC tests https://github.com/mt-mods/technic/tree/master/technic_cnc/spec
* Technic chests https://github.com/mt-mods/technic/tree/master/technic_chests/spec
* GitHub workflow https://github.com/mt-mods/technic/blob/master/.github/workflows/mineunit.yml

#### Metatool: complex multi mod test setup. Mineunit development began here.
* Metatool API tests https://github.com/S-S-X/metatool/tree/master/metatool/spec
* Containertool tests https://github.com/S-S-X/metatool/tree/master/containertool/spec
* Sharetool tests https://github.com/S-S-X/metatool/tree/master/sharetool/spec
* Tubetool tests https://github.com/S-S-X/metatool/tree/master/tubetool/spec
* GitHub workflow https://github.com/S-S-X/metatool/blob/master/.github/workflows/mineunit.yml

#### Other mods
* Advtrains (few simple tests for wagon registration) https://git.bananach.space/advtrains.git/tree/advtrains/spec
* Beerchat (chat commands and message delivery) https://github.com/minetest-beerchat/beerchat/tree/master/spec
* Digistuff (very simple, only load mod) https://github.com/mt-mods/digistuff/tree/master/spec
* Geoip (HTTP API) https://github.com/mt-mods/geoip/tree/master/spec
* Machine_parts https://github.com/mt-mods/machine_parts/tree/master/spec
* Mesecons (a bit different way to run mineunit) https://github.com/minetest-mods/mesecons/tree/master/mesecons/spec
* QoS (basic unit testing and chat commands) https://github.com/S-S-X/qos/tree/master/spec
* spectator_mode (player API and chat) https://github.com/minetest-mods/spectator_mode/tree/master/spec
