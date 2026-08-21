local Heartbeat = {}

function Heartbeat.start(auth, hwid, interval, onInvalid)
	interval = interval or 60
	local running = true
	local thread

	thread = task.spawn(function()
		while running do
			task.wait(interval)

			local ok = select(1, auth.heartbeat(hwid))

			if not ok and onInvalid then
				onInvalid()
				running = false
				break
			end
		end
	end)

	return function()
		running = false
	end
end

return Heartbeat
