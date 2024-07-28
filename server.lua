
--
-- Storage for node timers
--

mineunit("nodetimer")
mineunit("common/chatcommands")
mineunit("game/chat")

local world_nodetimers = {}
_G.core.get_node_timer = function(pos)
	local node_id = core.hash_node_position(pos)
	if not world_nodetimers[node_id] then
		world_nodetimers[node_id] = NodeTimerRef()
	end
	return world_nodetimers[node_id]
end

function mineunit:destroy_nodetimer(pos)
	local node_id = core.hash_node_position(pos)
	if world_nodetimers[node_id] then
		world_nodetimers[node_id] = nil
	end
end

local function match_nodes(nodename, nodegroups, nodes, groups)
	if nodes[nodename] then
		return true
	elseif nodegroups then
		for group,_ in pairs(nodegroups) do
			if groups[group] then
				return true
			end
		end
	end
	return false
end

local function match_neighbor(pos, nodes, groups)
	-- TODO: Make sure this is how engine actually looks for neighbors
	local rnodes = core.registered_nodes
	for x=-1,1 do
		for y=-1,1 do
			for z=-1,1 do
				-- Skip pos itself
				if not (x == 0 and y == 0 and z == 0) then
					local node = world.nodes[core.hash_node_position({x=x,y=y,z=z})]
					local name = node and node.name
					if name and match_nodes(name, rnodes[name] and rnodes[name].groups, nodes, groups) then
						return true
					end
				end
			end
		end
	end
end

local function get_nodes_and_groups(list)
	local nodes, groups = {}, {}
	for _,name in pairs(type(list) == "table" and list or {list}) do
		if name:sub(1,6) == "group:" then
			groups[name:sub(7)] = 1
		else
			nodes[name] = 1
		end
	end
	return nodes, groups
end

local function abm_cache(spec)
	if not spec._nodenames and spec.nodenames then
		spec._nodenames, spec._groupnames = get_nodes_and_groups(spec.nodenames)
		if not spec._neighbors_nodes and spec.neighbors then
			spec._neighbors_nodes, spec._neighbors_groups = get_nodes_and_groups(spec.neighbors)
		end
	end
end

local function run_abm(spec)
	abm_cache(spec)
	for id, node in pairs(world.nodes) do
		-- TODO: Allow spec.chance tests here? Ignored to keep results consistent and reproducible
		local nodegroups
		if spec._groupnames then
			nodegroups = core.registered_nodes[node.name] and core.registered_nodes[node.name].groups
		end
		if match_nodes(node.name, nodegroups, spec._nodenames, spec._groupnames) then
			local pos = core.get_position_from_hash(id)
			if not spec.neighbors or match_neighbor(pos, spec._neighbors_nodes, spec._neighbors_groups) then
				-- FIXME: active_object_count, active_object_count_wider. Entities not supported by mineunit.
				spec.action(pos, node, 0, 0)
			end
		end
	end
end

--
-- Execute callbacks
--

local RunCallbacksMode = {
	RUN_CALLBACKS_MODE_FIRST = 0,
	RUN_CALLBACKS_MODE_LAST = 1,
	RUN_CALLBACKS_MODE_AND = 2,
	RUN_CALLBACKS_MODE_AND_SC = 3,
	RUN_CALLBACKS_MODE_OR = 4,
	RUN_CALLBACKS_MODE_OR_SC = 5,
}

-- TODO: Add position / area filter. Allow changing collision data.
local entitystep_collision_data = {
	touching_ground = false,
	collides = false,
	standing_on_object = false,
	collisions = {}
}
function mineunit:execute_entitystep(dtime, filter)
	if filter then
		-- Execute on_step for named entities
		mineunit:debug("Executing entity step", filter)
		local list = mineunit:get_entities()[filter]
		for _, entity in ipairs(list) do
			entity:get_luaentity():on_step(dtime, table.copy(entitystep_collision_data))
		end
	else
		-- Execute on_step for all entities
		for group, list in pairs(mineunit:get_entities()) do
			mineunit:debug("Executing entity step", group)
			for _, entity in ipairs(list) do
				entity:get_luaentity():on_step(dtime, table.copy(entitystep_collision_data))
			end
		end
	end
end

function mineunit:execute_globalstep(dtime)
	-- Default server step is 0.1 seconds
	assert(dtime == nil or type(dtime) == "number", "Invalid call to mineunit:execute_globalstep")
	dtime = dtime or 0.1
	if mineunit:has_module("entity") then
		mineunit:execute_entitystep(dtime)
	end
	for node_id, timer in pairs(world_nodetimers) do
		timer:_step(dtime, core.get_position_from_hash(node_id))
	end
	for _,spec in pairs(core.registered_abms) do
		spec._dtime = spec._dtime and spec._dtime + dtime or dtime
		if spec._dtime >= spec.interval then
			run_abm(spec)
			spec._dtime = 0
		end
	end
	return core.run_callbacks(
		core.registered_globalsteps,
		RunCallbacksMode.RUN_CALLBACKS_MODE_FIRST,
		dtime
	)
end

function mineunit:execute_shutdown()
	return core.run_callbacks(
		core.registered_on_shutdown,
		RunCallbacksMode.RUN_CALLBACKS_MODE_FIRST
	)
end

function mineunit:execute_on_joinplayer(player, options)
	assert.is_Player(player, "mineunit:execute_on_joinplayer 1st arg should be Player")
	if options == nil then
		options = {}
	else
		assert.is_table(options, "mineunit:execute_on_joinplayer 2nd arg should be table or nil")
	end
	local address = options.address or "127.1.2.7"
	rawset(player, "_address", address)
	rawset(player, "_connection_info", {
		min_rtt = options.min_rtt or 0,
		max_rtt = options.max_rtt or 0,
		avg_rtt = options.avg_rtt or 0,
		min_jitter = options.min_jitter or 0,
		max_jitter = options.max_jitter or 0,
		avg_jitter = options.avg_jitter or 0,
	})
	local name = player:get_player_name()
	if core.get_auth_handler then
		local data = core.get_auth_handler().get_auth(name)
		core.set_player_privs(name, data.privileges)
		mineunit:debug("Auth privileges:", player:get_player_name(), dump(player._privs))
		local message = core.run_callbacks(
			core.registered_on_prejoinplayers,
			RunCallbacksMode.RUN_CALLBACKS_MODE_OR,
			name,
			address
		)
		if message then
			return message
		end
		mineunit:execute_globalstep()
	end
	player._online = true
	return core.run_callbacks(
		core.registered_on_joinplayers,
		RunCallbacksMode.RUN_CALLBACKS_MODE_FIRST,
		player,
		options.lastlogin
	)
end

function mineunit:execute_on_leaveplayer(player, timeout)
	assert.is_Player(player, "Invalid call to mineunit:execute_on_leaveplayer")
	player._online = false
	return core.run_callbacks(
		core.registered_on_leaveplayers,
		RunCallbacksMode.RUN_CALLBACKS_MODE_FIRST,
		player,
		timeout and true or false
	)
end

function mineunit:execute_on_chat_message(sender, message)
	assert(type(sender) == "string", "Invalid call to mineunit:execute_modchannel_message")
	assert(type(message) == "string", "Invalid call to mineunit:execute_modchannel_message")
	return core.run_callbacks(
		core.registered_on_chat_messages,
		RunCallbacksMode.RUN_CALLBACKS_MODE_OR_SC,
		sender,
		message
	)
end

function mineunit:execute_on_player_receive_fields(player, formname, fields)
	assert.is_Player(player, "Invalid call to mineunit:execute_on_player_receive_fields")
	assert.is_string(formname, "Invalid call to mineunit:execute_on_player_receive_fields")
	assert.is_table(fields, "Invalid call to mineunit:execute_on_player_receive_fields")
	return core.run_callbacks(
		core.registered_on_player_receive_fields,
		RunCallbacksMode.RUN_CALLBACKS_MODE_OR_SC,
		player,
		formname,
		fields
	)
end

function mineunit:execute_modchannel_message(channel, sender, message)
	-- TODO: Not tested at all
	assert(type(channel) == "string", "Invalid call to mineunit:execute_modchannel_message")
	assert(type(sender) == "string", "Invalid call to mineunit:execute_modchannel_message")
	assert(type(message) == "string", "Invalid call to mineunit:execute_modchannel_message")
	return core.run_callbacks(
		core.registered_on_modchannel_message,
		RunCallbacksMode.RUN_CALLBACKS_MODE_AND,
		channel,
		sender,
		message
	)
end

function mineunit:execute_modchannel_signal(channel, signal)
	-- TODO: Not tested at all
	assert(type(channel) == "string", "Invalid call to mineunit:execute_modchannel_signal")
	assert(type(signal) == "number" and math.floor(signal) == signal, "Invalid call to mineunit:execute_modchannel_signal")
	return core.run_callbacks(
		core.registered_on_modchannel_signal,
		RunCallbacksMode.RUN_CALLBACKS_MODE_AND,
		channel,
		signal
	)
end
