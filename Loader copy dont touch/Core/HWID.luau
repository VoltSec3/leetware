local HttpService = game:GetService("HttpService")
local RbxAnalyticsService = game:GetService("RbxAnalyticsService")

local HWID = {}

-- The real per-install identifier is the client id exposed by
-- RbxAnalyticsService. Mixing in executor name / user id / game id made the
-- value change between sessions and executors, which broke HWID checks. We use
-- the client id as the canonical HWID and only fall back to an executor's
-- gethwid() when the analytics service is unavailable.
function HWID.generate()
  local clientId = nil

  local ok, id = pcall(function()
    return RbxAnalyticsService:GetClientId()
  end)

  if ok and type(id) == "string" and id ~= "" then
    clientId = id
  elseif typeof(gethwid) == "function" then
    local ok2, hwid = pcall(gethwid)
    if ok2 and type(hwid) == "string" and hwid ~= "" then
      clientId = hwid
    end
  end

  if not clientId or clientId == "" then
    clientId = "unknown-hwid"
  end

  local okEnc, digest = pcall(function()
    return HttpService:Base64Encode(clientId)
  end)

  return okEnc and digest or clientId
end

return HWID
