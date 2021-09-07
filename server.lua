
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

local function match_nodenames(needle, strings)
	if type(strings) == "table" then
		for _,name in pairs(strings) do
			if name:sub(1,6) == "group:" then
				local group = name:sub(7)
				for _,nodedef in pairs(core.registered_nodes) do
					if nodedef.groups[group] then
						return true
					end
				end
			elseif name == needle then
				return true
			end
		end
	elseif strings:sub(1,6) == "group:" then
		local group = strings:sub(7)
		for _,nodedef in pairs(core.registered_nodes) do
			if nodedef.groups[group] then
				return true
			end
		end
	elseif strings == needle then
		return true
	end
	return false
end

local function match_neighbor(pos, nodenames)
	-- TODO: Make sure this is how engine actually looks for neighbors
	for x=-1,1 do
		for y=-1,1 do
			for z=-1,1 do
				-- Skip pos itself
				if not (x == 0 and y == 0 and z == 0) then
					local node = world.nodes[core.hash_node_position({x=x,y=y,z=z})]
					if node and match_nodenames(node.name, nodenames) then
						return true
					end
				end
			end
		end
	end
end

local function run_abm(spec)
	for id, node in pairs(world.nodes) do
		-- TODO: Allow spec.chance tests here? Ignored to keep results consistent and reproducible
		if match_nodenames(node.name, spec.nodenames) then
			local pos = core.get_position_from_hash(id)
			if not spec.neighbors or match_neighbor(pos, spec.neighbors) then
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

function mineunit:execute_globalstep(dtime)
	-- Default server step is 0.1 seconds
	assert(dtime == nil or type(dtime) == "number", "Invalid call to mineunit:execute_globalstep")
	dtime = dtime or 0.1
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

function mineunit:execute_on_joinplayer(player, lastlogin)
	assert.is_Player(player, "Invalid call to mineunit:execute_on_joinplayer")
	return core.run_callbacks(
		core.registered_on_joinplayers,
		RunCallbacksMode.RUN_CALLBACKS_MODE_FIRST,
		player,
		lastlogin
	)
end

function mineunit:execute_on_leaveplayer(player, timeout)
	assert.is_Player(player, "Invalid call to mineunit:execute_on_leaveplayer")
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
