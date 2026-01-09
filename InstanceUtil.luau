--!strict
-- InstanceUtil.lua

local InstanceUtil = {}


export type ClassName = string

function InstanceUtil.FindOrCreate<T>(
	parent: Instance,
	className: ClassName,
	name: string
): T
	local existing = parent:FindFirstChild(name)
	if existing then
		return existing :: T
	end

	local instance = Instance.new(className)
	instance.Name = name
	instance.Parent = parent

	return instance :: T
end

function InstanceUtil.WaitForChildSafe<T>(
	parent: Instance,
	childName: string,
	timeout: number?
): T?
	local result: Instance?

	local success = pcall(function()
		result = parent:WaitForChild(childName, timeout)
	end)

	if not success then
		return nil
	end

	return result :: T?
end

function InstanceUtil.AssertClass(
	instance: Instance?,
	expectedClass: ClassName
)
	assert(instance ~= nil, "[InstanceUtil] Instance is nil")
	assert(
		instance:IsA(expectedClass),
		(`[InstanceUtil] Expected {expectedClass}, got {instance.ClassName}`)
	)
end

function InstanceUtil.DestroyChildren(parent: Instance)
	for _, child in parent:GetChildren() do
		child:Destroy()
	end
end

function InstanceUtil.GetChildOfClass<T>(
	parent: Instance,
	className: ClassName
): T?
	for _, child in parent:GetChildren() do
		if child:IsA(className) then
			return child :: T
		end
	end
	return nil
end

return InstanceUtil
