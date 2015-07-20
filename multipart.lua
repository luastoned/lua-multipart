local multipart = {
	_VERSION		= "v1.0.0",
	_DESCRIPTION	= "Multipart encoding for Lua",
	_URL			= "https://github.com/luastoned/lua-multipart",
	_LICENSE		= [[Copyright (c) 2015 @LuaStoned]],
}

local function generateBoundary()
	local boundary = "--------------------------"
	for i = 1, 24 do
		-- 0 -> 9
		boundary = boundary .. math.random(0, 9)
		-- a -> z
		--boundary = boundary .. string.char(math.random(97, 122))
		-- A -> Z
		--boundary = boundary .. string.char(math.random(65, 90))
	end
	return boundary
end

local function appendData(request, key, data, extra)
	table.insert(request, string.format("Content-Disposition: form-data; name=\"%s\"", key))
	if extra.filename then
		table.insert(request, string.format("; filename=\"%s\"", extra.filename))
	end
	
	if extra.content_type then
		table.insert(request, string.format("\r\nContent-Type: %s", extra.content_type))
	end
	
	if extra.content_transfer_encoding then
		table.insert(request, string.format("\r\nContent-Transfer-Encoding: %s", extra.content_transfer_encoding))
	end
	
	table.insert(request, "\r\n\r\n")
	table.insert(request, data)
	table.insert(request, "\r\n")
end

local function encode(tbl, boundary)
	boundary = boundary or generateBoundary()
	
	local request = {}
	for key, part in pairs(tbl) do
		table.insert(request, string.format("--%s\r\n", boundary))
		local partType = type(part)
		if (partType == "string" or partType == "number") then
			appendData(request, key, part, {})
		elseif (partType == "table") then
			assert(part.data, "no data")
			local extra = {
				filename = part.filename or part.name,
				content_type = part.content_type or part.mimetype or "application/octet-stream",
				content_transfer_encoding = part.content_transfer_encoding or "binary",
			}
			appendData(request, key, part.data, extra)
		else
			error("unexpected type " .. partType)
		end
	end
	
	table.insert(request, string.format("--%s--\r\n", boundary))
	return table.concat(request), boundary
end

multipart.encode = encode
return multipart