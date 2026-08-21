local HttpService = game:GetService("HttpService")

local HWID = {}

local function getExecutorName()
	if typeof(identifyexecutor) == "function" then
		local ok, name = pcall(identifyexecutor)
		if ok and type(name) == "string" and name ~= "" then
			return name
		end
	end

	return "unknown"
end

-- Must be STABLE across launches: the server binds a license to this
-- fingerprint on first activation and rejects mismatches afterwards.
function HWID.generate()
	local parts = {}

	if typeof(gethwid) == "function" then
		local ok, hwid = pcall(gethwid)
		if ok and type(hwid) == "string" and hwid ~= "" then
			table.insert(parts, hwid)
		end
	end

	table.insert(parts, tostring(game:GetService("Players").LocalPlayer.UserId))
	table.insert(parts, getExecutorName())
	table.insert(parts, tostring(game.GameId))

	local fingerprint = table.concat(parts, "|")

	-- Hash locally so the raw fingerprint never leaves the device;
	-- the server applies its own HMAC before storage.
	local ok, digest = pcall(function()
		return HttpService:Base64Encode(fingerprint)
	end)

	if ok and type(digest) == "string" then
		return digest
	end

	return fingerprint
end

return HWID
