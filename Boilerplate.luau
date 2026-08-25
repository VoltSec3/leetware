--[[ leetware runtime guard: do not remove. this file only executes inside the official loader. ]]
do
	local function __leet_runtime_token()
		local seed = {0x6C,0x65,0x65,0x74,0x77,0x61,0x72,0x65,0x2D,0x72,0x74,0x2D,0x76,0x31}
		local key = {0x1F,0x3A,0x9C,0x55,0x7B,0x02,0xC4,0xED,0x36,0x88,0x4D,0x0B,0x91,0x5E}
		local out = {}
		for i = 1, #seed do
			out[i] = string.char(bit32.bxor(seed[i], key[((i - 1) % #key) + 1]))
		end
		return table.concat(out)
	end

	local rt = _G.__leet_rt
	if type(rt) ~= "table" or rt.active ~= true or type(rt.verify) ~= "function" then
		error("leetware: this script must be executed through the leetware loader.", 0)
	end

	local ok, provided = pcall(rt.verify)
	if not ok or provided ~= __leet_runtime_token() then
		error("leetware: runtime verification failed.", 0)
	end
end
--[[ end leetware runtime guard ]]

-- Universal boilerplate. Used as the fallback when the current GameId has no
-- dedicated game module. It cannot be executed outside the loader (see the
-- guard above) and is delivered through the authenticated API so its payload
-- can be edited from the dashboard without shipping a loader update.

local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local function notify(title, text)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = title,
			Text = text,
			Duration = 6,
		})
	end)
end

notify("leetware", "universal loader active - no dedicated config for this game")

-- The shared modules have already been pulled by the loader and are available
-- on _G.__leet_modules. Surface which ones are present for transparency.
local loaded = {}

for key, module in pairs(_G.__leet_modules or {}) do
	if type(module) == "table" and type(module.new) == "function" then
		table.insert(loaded, key)
	end
end

if #loaded > 0 then
	notify("leetware", "modules available: " .. table.concat(loaded, ", "))
end
