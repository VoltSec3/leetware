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

	local ok, digest = pcall(function()
		return HttpService:Base64Encode(fingerprint)
	end)

	if ok and type(digest) == "string" then
		return digest
	end

	return fingerprint
end

return HWID
