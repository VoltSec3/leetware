import { requireAdmin, requireCsrf } from "@/lib/admin-auth";
import { ensureSupportedGame } from "@/lib/game-service";
import { errorResponse, jsonResponse } from "@/lib/http";
import { prisma } from "@/lib/prisma";
import { upsertGameSchema } from "@/lib/validation";

export async function GET() {
  try {
    await requireAdmin();
  } catch {
    return errorResponse("Unauthorized", 401);
  }

  const [games, withPayload] = await Promise.all([
    prisma.supportedGame.findMany({
      orderBy: [{ enabled: "desc" }, { name: "asc" }],
      select: {
        id: true,
        gameId: true,
        name: true,
        moduleKey: true,
        delivery: true,
        scriptUrl: true,
        enabled: true,
        autoRegistered: true,
        lastSeenAt: true,
        createdAt: true,
        updatedAt: true,
      },
    }),
    prisma.supportedGame.findMany({
      where: { payloadSource: { not: null } },
      select: { id: true },
    }),
  ]);

  const payloadIds = new Set(withPayload.map((game) => game.id));

  return jsonResponse({
    games: games.map((game) => ({
      ...game,
      lastSeenAt: game.lastSeenAt?.toISOString() ?? null,
      createdAt: game.createdAt.toISOString(),
      updatedAt: game.updatedAt.toISOString(),
      hasPayloadSource: payloadIds.has(game.id),
    })),
  });
}

export async function POST(request: Request) {
  try {
    await requireAdmin();
  } catch {
    return errorResponse("Unauthorized", 401);
  }

  try {
    await requireCsrf(request);
  } catch {
    return errorResponse("Invalid CSRF token", 403);
  }

  let body: unknown;

  try {
    body = await request.json();
  } catch {
    return errorResponse("Invalid JSON body", 400);
  }

  const parsed = upsertGameSchema.safeParse(body);

  if (!parsed.success) {
    return errorResponse(parsed.error.issues[0]?.message ?? "Invalid request", 400);
  }

  const data = parsed.data;

  // Preserve an existing payloadSource when the field is omitted.
  const existing = await prisma.supportedGame.findUnique({
    where: { gameId: data.gameId },
  });

  const game = await ensureSupportedGame({
    gameId: data.gameId,
    name: data.name,
    moduleKey: data.moduleKey,
    scriptUrl: data.scriptUrl || undefined,
    delivery: data.delivery,
  });

  if (!game) {
    return errorResponse("Could not register game", 400);
  }

  const updated = await prisma.supportedGame.update({
    where: { id: game.id },
    data: {
      name: data.name,
      moduleKey: data.moduleKey ?? game.moduleKey,
      delivery: data.delivery ?? game.delivery,
      scriptUrl: data.scriptUrl === "" ? null : (data.scriptUrl ?? game.scriptUrl),
      payloadSource:
        data.payloadSource !== undefined
          ? data.payloadSource || null
          : (existing?.payloadSource ?? null),
      enabled: data.enabled ?? true,
      autoRegistered: false,
    },
  });

  return jsonResponse({
    game: {
      id: updated.id,
      gameId: updated.gameId,
      name: updated.name,
      moduleKey: updated.moduleKey,
      delivery: updated.delivery,
      scriptUrl: updated.scriptUrl,
      enabled: updated.enabled,
      autoRegistered: updated.autoRegistered,
      hasPayloadSource: Boolean(updated.payloadSource),
      lastSeenAt: updated.lastSeenAt?.toISOString() ?? null,
      createdAt: updated.createdAt.toISOString(),
      updatedAt: updated.updatedAt.toISOString(),
    },
  });
}
