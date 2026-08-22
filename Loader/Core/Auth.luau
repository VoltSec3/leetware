local HttpService = game:GetService("HttpService")

local Config = loadstring(game:HttpGet(
	"https://raw.githubusercontent.com/VoltSec3/leetware/main/Loader/Core/Config.luau"
))()

local Auth = {}
Auth._sessionToken = nil
Auth._sessionExpiresAt = 0

local function request(method, path, body, headers)
	headers = headers or {}

	local requestPayload = {
		Url = Config.API_BASE .. path,
		Method = method,
		Headers = {
			["Content-Type"] = "application/json",
			["Accept"] = "application/json",
		},
		Body = body and HttpService:JSONEncode(body) or nil,
	}

	for key, value in pairs(headers) do
		requestPayload.Headers[key] = value
	end

	local response

	if syn and syn.request then
		response = syn.request(requestPayload)
	elseif http and http.request then
		response = http.request(requestPayload)
	elseif request then
		response = request(requestPayload)
	else
		return false, "No HTTP request function available"
	end

	if not response or not response.Body then
		return false, "Empty response"
	end

	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(response.Body)
	end)

	if not ok then
		return false, "Invalid JSON response"
	end

	if response.StatusCode >= 400 then
		return false, decoded.error or ("HTTP " .. tostring(response.StatusCode)), decoded
	end

	return true, decoded
end

local function ensureFolder(path)
	local parts = string.split(path, "/")
	local current = ""

	for index, part in ipairs(parts) do
		if index < #parts then
			current = current == "" and part or current .. "/" .. part
			if makefolder and not isfolder(current) then
				makefolder(current)
			end
		end
	end
end

function Auth.saveLicense(license)
	if not writefile then
		return
	end

	ensureFolder("leetware")
	writefile(Config.LICENSE_FILE, license)
end

function Auth.loadLicense()
	if not readfile or not isfile then
		return nil
	end

	if not isfile(Config.LICENSE_FILE) then
		return nil
	end

	return readfile(Config.LICENSE_FILE)
end

function Auth.saveSession(token, expiresAt)
	Auth._sessionToken = token
	Auth._sessionExpiresAt = expiresAt

	if not writefile then
		return
	end

	ensureFolder("leetware")
	writefile(
		Config.SESSION_FILE,
		HttpService:JSONEncode({
			token = token,
			expiresAt = expiresAt,
		})
	)
end

function Auth.loadSession()
	if Auth._sessionToken and Auth._sessionExpiresAt > os.time() then
		return Auth._sessionToken
	end

	if not readfile or not isfile or not isfile(Config.SESSION_FILE) then
		return nil
	end

	local ok, data = pcall(function()
		return HttpService:JSONDecode(readfile(Config.SESSION_FILE))
	end)

	if not ok or type(data) ~= "table" then
		return nil
	end

	if type(data.expiresAt) == "number" and data.expiresAt <= os.time() then
		return nil
	end

	Auth._sessionToken = data.token
	Auth._sessionExpiresAt = data.expiresAt or 0

	return Auth._sessionToken
end

function Auth.getSessionToken()
	return Auth._sessionToken
end

-- Best-effort game context so the API can auto-register new games.
local function gameContext()
	if not Config.REPORT_GAME_CONTEXT then
		return {}
	end

	local context = {
		gameId = tostring(game.PlaceId),
	}

	local ok, name = pcall(function()
		return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
	end)

	if ok and type(name) == "string" and #name > 0 then
		context.gameName = name
	end

	return context
end

local function withGameContext(body)
	local context = gameContext()

	for key, value in pairs(context) do
		body[key] = value
	end

	return body
end

function Auth.authenticate(license, hwid)
	local savedSession = Auth.loadSession()
	local player = game:GetService("Players").LocalPlayer
	local identity = {
		metadata = {
			robloxUsername = (player and player.Name) or nil,
			robloxDisplayName = (player and player.DisplayName) or nil,
			robloxUserId = (player and player.UserId) or nil,
		},
	}

	if savedSession then
		local ok, data = request("POST", "/auth/session", withGameContext({
			sessionToken = savedSession,
			hwid = hwid,
			clientVersion = Config.CLIENT_VERSION,
			metadata = identity.metadata,
		}))

		if ok then
			Auth.saveSession(data.sessionToken, os.time() + 900)
			return true, data
		end
	end

	local ok, data = request("POST", "/auth/activate", withGameContext({
		license = license,
		hwid = hwid,
		clientVersion = Config.CLIENT_VERSION,
		metadata = identity.metadata,
	}))

	if ok then
		Auth.saveLicense(license)
		Auth.saveSession(data.sessionToken, os.time() + 900)
		return true, data
	end

	ok, data = request("POST", "/auth/session", withGameContext({
		license = license,
		hwid = hwid,
		clientVersion = Config.CLIENT_VERSION,
		metadata = identity.metadata,
	}))

	if ok then
		Auth.saveLicense(license)
		Auth.saveSession(data.sessionToken, os.time() + 900)
		return true, data
	end

	return false, data
end

-- Unauthenticated GET helper (public endpoints such as /games).
function Auth.get(path)
	return request("GET", path)
end

-- Fetch a protected module through the API (session + HWID gated).
-- The server decides authorization; it returns 401/403/404 on failure.
function Auth.payload(moduleKey, hwid)
	local token = Auth.getSessionToken() or Auth.loadSession()

	if not token then
		return false, "No active session"
	end

	local requestPayload = {
		Url = Config.API_BASE .. "/payload/" .. moduleKey,
		Method = "GET",
		Headers = {
			["Authorization"] = "Bearer " .. token,
			["X-HWID"] = hwid,
			["Accept"] = "text/plain",
		},
	}

	local response

	if syn and syn.request then
		response = syn.request(requestPayload)
	elseif http and http.request then
		response = http.request(requestPayload)
	elseif request then
		response = request(requestPayload)
	else
		return false, "No HTTP request function available"
	end

	if not response or not response.Body then
		return false, "Empty response"
	end

	if response.StatusCode >= 400 then
		return false, "Payload denied (HTTP " .. tostring(response.StatusCode) .. ")"
	end

	local ok, data = pcall(function()
		return HttpService:JSONDecode(response.Body)
	end)

	if ok and type(data) == "table" and data.payload and data.payload.available == false then
		return false, data.payload.message or "Payload is not available"
	end

	return true, response.Body
end

function Auth.validate(hwid)
	local token = Auth.getSessionToken() or Auth.loadSession()

	if not token then
		return false, "No active session"
	end

	local ok, data = request("POST", "/auth/validate", withGameContext({
		sessionToken = token,
		hwid = hwid,
	}))

	return ok and data.valid == true, data
end

function Auth.heartbeat(hwid)
	local token = Auth.getSessionToken() or Auth.loadSession()

	if not token then
		return false, "No active session"
	end

	local ok, data = request("POST", "/auth/heartbeat", withGameContext({
		sessionToken = token,
		hwid = hwid,
	}))

	if ok and data.valid then
		Auth.saveSession(token, os.time() + 900)
	end

	return ok and data.valid == true, data
end

return Auth
