--!strict
-- Cooldown.lua

local Cooldown = {}
Cooldown.__index = Cooldown

export type Owner = any
export type Key = string

type CooldownEntry = {
	expiresAt: number,
	duration: number,
	locked: boolean,
}

local storage: {[Owner]: {[Key]: CooldownEntry}} = {}

-- Internal
local function getBucket(owner: Owner)
	local bucket = storage[owner]
	if not bucket then
		bucket = {}
		storage[owner] = bucket
	end
	return bucket
end

local function cleanupIfEmpty(owner: Owner)
	local bucket = storage[owner]
	if not bucket then return end
	if next(bucket) == nil then
		storage[owner] = nil
	end
end

function Cooldown:IsActive(owner: Owner, key: Key): boolean
	local bucket = storage[owner]
	if not bucket then return false end

	local entry = bucket[key]
	if not entry then return false end

	if os.clock() >= entry.expiresAt then
		bucket[key] = nil
		cleanupIfEmpty(owner)
		return false
	end

	return true
end

function Cooldown:GetRemaining(owner: Owner, key: Key): number
	local bucket = storage[owner]
	if not bucket then return 0 end

	local entry = bucket[key]
	if not entry then return 0 end

	return math.max(0, entry.expiresAt - os.clock())
end

function Cooldown:Set(
	owner: Owner,
	key: Key,
	duration: number,
	overwrite: boolean?
)
	local bucket = getBucket(owner)
	local now = os.clock()

	local existing = bucket[key]
	if existing and not overwrite and existing.locked then
		return
	end

	bucket[key] = {
		duration = duration,
		expiresAt = now + duration,
		locked = false,
	}
end

function Cooldown:Extend(owner: Owner, key: Key, extraTime: number)
	local bucket = storage[owner]
	if not bucket then return end

	local entry = bucket[key]
	if not entry then return end

	entry.expiresAt += extraTime
end

function Cooldown:Lock(owner: Owner, key: Key)
	local bucket = getBucket(owner)
	local entry = bucket[key]
	if entry then
		entry.locked = true
	end
end

function Cooldown:Clear(owner: Owner, key: Key)
	local bucket = storage[owner]
	if not bucket then return end

	bucket[key] = nil
	cleanupIfEmpty(owner)
end

function Cooldown:ClearAll(owner: Owner)
	storage[owner] = nil
end

function Cooldown:ClearKeyEverywhere(key: Key)
	for owner, bucket in pairs(storage) do
		bucket[key] = nil
		cleanupIfEmpty(owner)
	end
end

return Cooldown




--Exemple
--It works for any player, ID, or instance.

if Cooldown:IsActive(player, "Dash") then return end
Cooldown:Set(player, "Dash", 2)
