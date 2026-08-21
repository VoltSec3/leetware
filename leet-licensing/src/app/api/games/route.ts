import { jsonResponse } from "@/lib/http";
import { listEnabledGames } from "@/lib/game-service";

// Public, unauthenticated catalog of enabled games. Loaders merge this with
// their built-in registry, which lets new games go live without shipping a
// loader update. payloadSource is intentionally never exposed here.
export async function GET() {
  const games = await listEnabledGames();

  return jsonResponse({
    games: games.map((game) => ({
      gameId: game.gameId,
      name: game.name,
      moduleKey: game.moduleKey,
      delivery: game.delivery === "api" ? "api" : "direct",
      scriptUrl: game.delivery === "api" ? null : game.scriptUrl,
    })),
    fallback: {
      moduleKey: "boilerplate",
      delivery: "direct",
      scriptUrl:
        "https://raw.githubusercontent.com/VoltSec3/leetware/main/Boilerplate.luau",
      description:
        "Used when the current GameId has no registered game module.",
    },
  });
}
