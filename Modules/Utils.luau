-- leetware runtime guard: do not remove. this file only executes inside the official loader.
do
  local function __leet_expected()
    return "8293d0c9ceeffc85"
  end
  local function __leet_key()
    return "utils"
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

local Utils = {}

-- Returns every player currently in the supplied Players service.
function Utils.GetPlayers(players)
    return players:GetPlayers()
end

-- Returns the number of players currently in the supplied Players service.
function Utils.GetPlayerCount(players)
    return #Utils.GetPlayers(players)
end

-- Returns players whose Team matches the supplied team.
function Utils.GetPlayersOnTeam(players, team)
    local result = {}

    for _, player in ipairs(players:GetPlayers()) do
        if player.Team == team then
            table.insert(result, player)
        end
    end

    return result
end

-- Returns the distinct teams currently represented by players.
function Utils.GetTeams(players)
    local teams = {}
    local seen = {}

    for _, player in ipairs(players:GetPlayers()) do
        local team = player.Team

        if team and not seen[team] then
            seen[team] = true
            table.insert(teams, team)
        end
    end

    table.sort(teams, function(left, right)
        return left.Name < right.Name
    end)

    return teams
end

-- Returns the number of distinct teams currently represented by players.
function Utils.GetTeamCount(players)
    return #Utils.GetTeams(players)
end

-- Returns team names suitable for Linoria dropdown values.
function Utils.GetTeamNames(players)
    local names = {}

    for _, team in ipairs(Utils.GetTeams(players)) do
        table.insert(names, team.Name)
    end

    return names
end

-- Returns a player's current team name, or Neutral when they have no team.
function Utils.GetTeamName(player)
    return player.Team and player.Team.Name or "Neutral"
end

-- Returns a character's Humanoid, if present.
function Utils.GetHumanoid(player)
    local character = player and player.Character
    return character and character:FindFirstChildOfClass("Humanoid")
end

-- Returns a character's named body part, if present.
function Utils.GetBodyPart(player, partName)
    local character = player and player.Character
    return Utils.GetCharacterPart(character, partName)
end

-- Returns a named part directly from a character model, if present.
function Utils.GetCharacterPart(character, partName)
    return character and character:FindFirstChild(partName)
end

-- Returns the player's HumanoidRootPart, if present.
function Utils.GetRootPart(player)
    return Utils.GetBodyPart(player, "HumanoidRootPart")
end

-- Returns the player's Head, if present.
function Utils.GetHead(player)
    return Utils.GetBodyPart(player, "Head")
end

-- Returns the tool currently parented to the player's character.
function Utils.GetEquippedTool(player)
    local character = player and player.Character

    if not character then
        return nil
    end

    return character:FindFirstChildOfClass("Tool")
end

-- Returns the equipped tool name, or nil when no tool is equipped.
function Utils.GetEquippedToolName(player)
    local tool = Utils.GetEquippedTool(player)
    return tool and tool.Name or nil
end

-- Returns whether the player's Humanoid exists and is alive.
function Utils.IsAlive(player)
    local humanoid = Utils.GetHumanoid(player)
    return humanoid ~= nil and humanoid.Health > 0
end

-- Returns the distance between two BaseParts or positions.
function Utils.GetDistance(first, second)
    local firstPosition = typeof(first) == "Vector3"
        and first
        or first.Position
    local secondPosition = typeof(second) == "Vector3"
        and second
        or second.Position

    return (firstPosition - secondPosition).Magnitude
end

-- Returns a player's distance from a world position, or nil if unavailable.
function Utils.GetPlayerDistance(player, position)
    local root = Utils.GetRootPart(player)

    if not root then
        return nil
    end

    return Utils.GetDistance(root.Position, position)
end

-- Returns the player's display name, username, or a selected name mode.
function Utils.GetPlayerName(player, useDisplayName)
    if useDisplayName then
        return player.DisplayName
    end

    return player.Name
end

-- Returns whether two players are on the same non-nil team.
function Utils.AreTeammates(first, second)
    return first.Team ~= nil
        and second.Team ~= nil
        and first.Team == second.Team
end

-- Returns whether the local player is friends with the supplied player.
function Utils.IsFriend(localPlayer, player)
    local success, isFriend = pcall(function()
        return localPlayer:IsFriendsWith(player.UserId)
    end)

    return success and isFriend
end

return Utils