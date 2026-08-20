# Utils

`Utils.luau` contains shared player, team, character, distance, and friendship helpers. Functions accept the Roblox `Players` service or a `Player` instance as described below.

## Player and Team Queries

- `GetPlayers(players)` returns the current player list.
- `GetPlayerCount(players)` returns the current player count.
- `GetPlayersOnTeam(players, team)` returns players assigned to `team`.
- `GetTeams(players)` returns distinct active `Team` instances sorted by name.
- `GetTeamCount(players)` returns the number of distinct active teams.
- `GetTeamNames(players)` returns sorted team names for dropdowns.
- `GetTeamName(player)` returns the player's team name, or `Neutral`.

## Character Queries

- `GetHumanoid(player)` returns the player's Humanoid, if available.
- `GetBodyPart(player, partName)` returns a named character part.
- `GetCharacterPart(character, partName)` returns a named part from a character model.
- `GetRootPart(player)` returns `HumanoidRootPart`, if available.
- `GetHead(player)` returns `Head`, if available.
- `IsAlive(player)` returns whether the player's Humanoid is alive.
- `GetEquippedTool(player)` returns the tool currently equipped by the player.
- `GetEquippedToolName(player)` returns the equipped tool name, or nil.

## Player Helpers

- `GetDistance(first, second)` returns the distance between two `Vector3` values or BaseParts.
- `GetPlayerDistance(player, position)` returns the player's root distance from a world position.
- `GetPlayerName(player, useDisplayName)` returns the display name when enabled, otherwise the username.
- `AreTeammates(first, second)` checks whether both players share a non-nil team.
- `IsFriend(localPlayer, player)` safely checks the Roblox friendship relationship.

## Example

```lua
local Utils = loadstring(game:HttpGet(utilsRepo))()

local teamNames = Utils.GetTeamNames(Players)
local alive = Utils.IsAlive(target)
local distance = Utils.GetPlayerDistance(target, Workspace.CurrentCamera.CFrame.Position)
```
