-- leetware runtime guard: do not remove. this file only executes inside the official loader.
do
  local function __leet_expected()
    return "442d62f3b029ae4f"
  end
  local function __leet_key()
    return "boilerplate"
  end
  local rt = _G.__leet_rt
  if type(rt) ~= "table" or rt.active ~= true or type(rt.verify) ~= "function" then
    error("leetware: this script must be executed through the leetware loader.", 0)
  end
  local ok, provided = pcall(rt.verify, __leet_key())
  if not ok or provided ~= __leet_expected() then
    error("leetware: runtime verification failed.", 0)
  end
end
-- leetware runtime guard end

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
