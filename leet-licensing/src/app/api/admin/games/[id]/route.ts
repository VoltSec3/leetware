import { requireRole } from "@/lib/admin-auth";
import { errorResponse, jsonResponse } from "@/lib/http";
import { prisma } from "@/lib/prisma";

type RouteContext = {
  params: Promise<{ id: string }>;
};

// Returns a single game/module including its gated payload source. Admin-only;
// the list endpoint intentionally omits payloadSource to keep responses light.
export async function GET(_request: Request, context: RouteContext) {
  try {
    await requireRole(["ADMIN", "SUPPORT"]);
  } catch {
    return errorResponse("Unauthorized", 401);
  }

  const { id } = await context.params;

  const game = await prisma.supportedGame.findUnique({
    where: { id },
    select: {
      id: true,
      gameId: true,
      name: true,
      moduleKey: true,
      delivery: true,
      kind: true,
      locked: true,
      scriptUrl: true,
      payloadSource: true,
      enabled: true,
      autoRegistered: true,
      lastSeenAt: true,
      createdAt: true,
      updatedAt: true,
    },
  });

  if (!game) {
    return errorResponse("Game not found", 404);
  }

  return jsonResponse({
    game: {
      ...game,
      lastSeenAt: game.lastSeenAt?.toISOString() ?? null,
      createdAt: game.createdAt.toISOString(),
      updatedAt: game.updatedAt.toISOString(),
      hasPayloadSource: Boolean(game.payloadSource),
    },
  });
}
