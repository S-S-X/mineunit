local NodeTimerRef = {}

--
-- NodeTimerRef Mineunit execution API
--

function NodeTimerRef:_step(dtime, pos)
	if self:is_started() then
		self._elapsed = self._elapsed + (dtime or 0.1)
		if pos then
			self:_execute(pos)
		end
	end
end

function NodeTimerRef:_execute(pos)
	local elapsed = self:get_elapsed()
	local timeout = self:get_timeout()
	local dtime = elapsed - timeout
	if self:is_started() and dtime >= 0 then
		local on_timer = core.registered_nodes[core.get_node(pos).name].on_timer
		local result = on_timer(pos, dtime)
		if result == true then
			self:start(timeout)
		else
			-- TODO: Check if trashing data is expected behavior or should timer be stopped without trashing data
			self:stop()
		end
	end
end

--
-- NodeTimerRef public API
--

-- set a timer's state
-- `timeout` is in seconds, and supports fractional values (0.1 etc)
-- `elapsed` is in seconds, and supports fractional values (0.1 etc)
-- will trigger the node's `on_timer` function after `(timeout - elapsed)` seconds.
function NodeTimerRef:set(timeout,elapsed)
	self._timeout = timeout
	self._elapsed = elapsed
end

-- start a timer, equivalent to `set(timeout,0)`
function NodeTimerRef:start(timeout)
	self._timeout = timeout
	self._elapsed = 0
end

-- stops the timer
function NodeTimerRef:stop()
	self._timeout = 0
	self._elapsed = 0
end

-- if `timeout` equals `0`, timer is inactive
function NodeTimerRef:get_timeout()
	return self._timeout
end

-- the node's `on_timer` function will be called after `(timeout - elapsed)` seconds.
function NodeTimerRef:get_elapsed()
	return self._elapsed
end

-- returns `true` if timer is started, otherwise `false`
function NodeTimerRef:is_started()
	return self:get_timeout() > 0
end

mineunit.export_object(NodeTimerRef, {
	name = "NodeTimerRef",
	constructor = function(self)
		local obj = {
			_timeout = 0,
			_elapsed = 0,
		}
		setmetatable(obj, NodeTimerRef)
		return obj
	end,
})
