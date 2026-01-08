local Crypt = {}

-- Transforma qualquer tipo de dado em uma string de bytes (Buffer)
local function toBytes(value: any): buffer
	if type(value) == "boolean" then
		local b = buffer.create(1)
		buffer.writeu8(b, 0, value and 1 or 0)
		return b
	elseif type(value) == "string" then
		return buffer.fromstring(value)
	elseif typeof(value) == "CFrame" then
		local b = buffer.create(48) -- 12 floats de 4 bytes cada
		local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = value:GetComponents()
		local components = {x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22}
		for i, v in ipairs(components) do
			buffer.writef32(b, (i-1) * 4, v)
		end
		return b
	end
	error("Tipo não suportado")
end

function Crypt.process(dataBuffer: buffer, key: string): buffer
	local keyLen = #key
	local dataLen = buffer.len(dataBuffer)
	local result = buffer.create(dataLen)
	
	for i = 0, dataLen - 1 do
		local keyByte = string.byte(key, (i % keyLen) + 1)
		local dataByte = buffer.readu8(dataBuffer, i)
		
		-- XOR seguido de uma inversão de bits (NOT)
		local transformed = bit32.bxor(dataByte, keyByte)
		buffer.writeu8(result, i, transformed)
	end
	
	return result
end

-- Função para converter de volta para o tipo original
function Crypt.toType(b: buffer, targetType: string): any
	if targetType == "boolean" then
		return buffer.readu8(b, 0) == 1
	elseif targetType == "string" then
		return buffer.tostring(b)
	elseif targetType == "CFrame" then
		local c = {}
		for i = 1, 12 do
			table.insert(c, buffer.readf32(b, (i-1) * 4))
		end
		return CFrame.new(unpack(c))
	end
end

return Crypt

