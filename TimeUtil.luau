--!strict
-- TimeUtil.lua

local TimeUtil = {}

-- Tipo do token retornado por After / Every
export type TimerToken = {
	Id: number,
	Cancel: () -> (),
}

local nextId = 0
local activeTimers: { [number]: boolean } = {}

function TimeUtil.After(seconds: number, callback: () -> ()): TimerToken
	nextId += 1
	local id = nextId
	activeTimers[id] = true

	local function cancel()
		activeTimers[id] = false
	end

	task.spawn(function()
		task.wait(seconds)
		if activeTimers[id] then
			callback()
			activeTimers[id] = false
		end
	end)

	return { Id = id, Cancel = cancel }
end

function TimeUtil.Every(seconds: number, callback: () -> ()): TimerToken
	nextId += 1
	local id = nextId
	activeTimers[id] = true

	local function cancel()
		activeTimers[id] = false
	end

	task.spawn(function()
		while activeTimers[id] do
			task.wait(seconds)
			if activeTimers[id] then
				callback()
			end
		end
	end)

	return { Id = id, Cancel = cancel }
end

function TimeUtil.Cancel(token: TimerToken)
	if token and token.Cancel then
		token.Cancel()
	end
end

return TimeUtil
