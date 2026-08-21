local baseUrl = "https://raw.githubusercontent.com/VoltSec3/leetware/main/"

local function loadModule(path, name)
	local source = game:HttpGet(baseUrl .. path)
	local chunk, compileError = loadstring(source)

	assert(
		chunk,
		string.format("Failed to compile %s: %s", name, tostring(compileError))
	)

	return chunk()
end

local Config = loadModule("Loader/Core/Config.luau", "Config")
local HWID = loadModule("Loader/Core/HWID.luau", "HWID")
local Auth = loadModule("Loader/Core/Auth.luau", "Auth")
local Heartbeat = loadModule("Loader/Core/Heartbeat.luau", "Heartbeat")
local Dispatcher = loadModule("Loader/Core/Dispatcher.luau", "Dispatcher")
local UI = loadModule("Loader/UI/Login.luau", "UI")

local hwid = HWID.generate()
local stopHeartbeat = nil

local function startHeartbeat()
	if stopHeartbeat then
		stopHeartbeat()
	end

	stopHeartbeat = Heartbeat.start(Auth, hwid, Config.HEARTBEAT_INTERVAL, function()
		warn("[leetware] Session invalidated. Reload the loader.")
	end)
end

local function runLoader(setStatus, closeUi)
	setStatus("Validating session...", Color3.fromRGB(180, 180, 190))

	local valid = Auth.validate(hwid)
	if not valid then
		return false, "Session validation failed"
	end

	setStatus("Detecting game module...", Color3.fromRGB(180, 180, 190))

	local gameEntry = Dispatcher.resolve(nil, Auth)
	if gameEntry then
		setStatus("Loading " .. gameEntry.name .. "...", Color3.fromRGB(180, 180, 190))
	else
		setStatus("Loading universal boilerplate...", Color3.fromRGB(180, 180, 190))
	end

	local ok, err = pcall(function()
		Dispatcher.load(Auth, hwid)
	end)

	if not ok then
		return false, err
	end

	startHeartbeat()
	closeUi()
	return true
end

local loaderUi = UI.create(function(license, setStatus, closeUi)
	setStatus("Authenticating license...", Color3.fromRGB(180, 180, 190))

	local ok, result = Auth.authenticate(license, hwid)
	if not ok then
		local message = type(result) == "string" and result or (result and result.error) or "Authentication failed"
		return false, message
	end

	return runLoader(setStatus, closeUi)
end)

-- Auto-resume if saved license + session exist
task.defer(function()
	local savedLicense = Auth.loadLicense()
	local savedSession = Auth.loadSession()

	if savedLicense and savedSession then
		local ok = Auth.validate(hwid)
		if ok then
			local loaded = pcall(function()
				Dispatcher.load(Auth, hwid)
			end)

			if loaded then
				startHeartbeat()
				if loaderUi then
					loaderUi:Destroy()
					loaderUi = nil
				end
			end
		end
	end
end)
