
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
