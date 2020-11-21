# mineunit
Minetest core / engine libraries for regression tests

### How to use mineunit
```bash
$ cd my_minetest_mod/spec/fixtures
$ git submodule add git@github.com:mt-mods/mineunit.git
```

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
