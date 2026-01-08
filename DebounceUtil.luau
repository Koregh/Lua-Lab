--!strict
-- DebounceUtil.lua

local Players = game:GetService("Players")

local DebounceUtil = {}


export type Config = {
	Cooldown: number,          -- tempo mínimo entre execuções
	MaxCalls: number,          -- chamadas permitidas na janela
	Window: number,            -- duração da janela
	MaxAbuse: number,          -- quantos abusos antes da punição
	Punishment: "Kick" | "Warn" | "None",
}

type CallTimestamps = { number }

type ActionData = {
	LastCall: number,
	Calls: CallTimestamps,
	AbuseCount: number,
}

type UserData = {
	[string]: ActionData
}

local data: { [number]: UserData } = {}

local function getUserData(userId: number): UserData
	local user = data[userId]
	if not user then
		user = {}
		data[userId] = user
	end
	return user
end

local function punish(player: Player, config: Config)
	if config.Punishment == "Kick" then
		player:Kick("Abuso de eventos detectado.")
	elseif config.Punishment == "Warn" then
		warn("[DebounceUtil] Abuso detectado:", player.Name)
	end
end

function DebounceUtil:CanRun(player: Player, action: string, config: Config): boolean
	local now = os.clock()
	local userData = getUserData(player.UserId)

	local actionData = userData[action]
	if not actionData then
		actionData = {
			LastCall = 0,
			Calls = {},
			AbuseCount = 0,
		}
		userData[action] = actionData
	end

	-- COOLDOWN
	if (now - actionData.LastCall) < config.Cooldown then
		actionData.AbuseCount += 1
		if actionData.AbuseCount >= config.MaxAbuse then
			punish(player, config)
		end
		return false
	end

	actionData.LastCall = now

	-- RATE LIMIT (janela)
	local calls = actionData.Calls
	local windowStart = now - config.Window

	-- limpa chamadas antigas
	local i = 1
	while i <= #calls do
		if calls[i] < windowStart then
			table.remove(calls, i)
		else
			i += 1
		end
	end

	if #calls >= config.MaxCalls then
		actionData.AbuseCount += 1
		if actionData.AbuseCount >= config.MaxAbuse then
			punish(player, config)
		end
		return false
	end

	table.insert(calls, now)
	return true
end

function DebounceUtil:ClearPlayer(player: Player)
	data[player.UserId] = nil
end

Players.PlayerRemoving:Connect(function(player)
	data[player.UserId] = nil
end)

return DebounceUtil
