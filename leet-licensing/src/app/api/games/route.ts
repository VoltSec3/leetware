import { jsonResponse } from "@/lib/http";
import { listGames } from "@/lib/game-service";

// Public, unauthenticated catalog of enabled games. Loaders merge this with
// their built-in registry, which lets new games go live without shipping a
// loader update. payloadSource is intentionally never exposed here.
export async function GET() {
  const games = await listGames();

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
      delivery: "api",
      description:
        "Universal fallback served via the authenticated payload endpoint when the current GameId has no registered game module.",
    },
  });
}
