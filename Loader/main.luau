local baseUrl = "https://raw.githubusercontent.com/VoltSec3/leetware/main/"
local subloaderUrl = baseUrl .. "Loader/Subloader.luau"

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

local function runSubloader()
	local source = game:HttpGet(subloaderUrl)
	local chunk, compileError = loadstring(source)

	assert(
		chunk,
		string.format("Failed to compile subloader: %s", tostring(compileError))
	)

	return chunk()(Auth, hwid)
end

local function runLoader(setStatus, closeUi)
	setStatus("Validating session...", Color3.fromRGB(180, 180, 190))

	local valid = Auth.validate(hwid)
	if not valid then
		return false, "Session validation failed"
	end

	setStatus("Loading game module...", Color3.fromRGB(180, 180, 190))

	local ok, err = pcall(function()
		runSubloader()
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

task.defer(function()
	local savedLicense = Auth.loadLicense()
	local savedSession = Auth.loadSession()

	if savedLicense and savedSession then
		local ok = Auth.validate(hwid)
		if ok then
			local loaded = pcall(function()
				runSubloader()
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
