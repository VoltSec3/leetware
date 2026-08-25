import { requireCsrf, requireRole } from "@/lib/admin-auth";
import {
  ensureSupportedGame,
  PROTECTED_GAMEOBJECTS,
} from "@/lib/game-service";
import { errorResponse, jsonResponse } from "@/lib/http";
import { prisma } from "@/lib/prisma";
import { ensureRuntimeGuard } from "@/lib/runtime-guard";
import { upsertGameSchema } from "@/lib/validation";

export async function GET() {
  try {
    await requireRole(["ADMIN", "SUPPORT"]);
  } catch {
    return errorResponse("Unauthorized", 401);
  }

  const [games, withPayload] = await Promise.all([
    prisma.supportedGame.findMany({
      orderBy: [{ kind: "asc" }, { enabled: "desc" }, { name: "asc" }],
      select: {
        id: true,
        gameId: true,
        name: true,
        moduleKey: true,
        delivery: true,
        scriptUrl: true,
        enabled: true,
        autoRegistered: true,
        kind: true,
        locked: true,
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
    await requireRole(["ADMIN"]);
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
  const kind = data.kind === "module" ? "module" : "game";

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
    kind,
  });

  if (!game) {
    return errorResponse("Could not register game", 400);
  }

  // Built-in entries (boilerplate + the 5 modules) are locked so they can be
  // edited but never deleted or renamed.
  const locked =
    game.locked ||
    (kind === "module" && PROTECTED_GAMEOBJECTS.includes(data.moduleKey ?? ""));

  // Always bind a runtime guard to the saved payload so it cannot be executed
  // directly outside the loader. The guard key is the module key (falling back
  // to the game id) and is what the loader passes to rt.verify.
  const guardKey = data.moduleKey || data.gameId;
  const nextPayload =
    data.payloadSource !== undefined
      ? data.payloadSource
        ? ensureRuntimeGuard(guardKey, data.payloadSource)
        : null
      : (existing?.payloadSource ?? null);

  const updated = await prisma.supportedGame.update({
    where: { id: game.id },
    data: {
      name: data.name,
      moduleKey: data.moduleKey ?? game.moduleKey,
      delivery: data.delivery ?? game.delivery,
      kind,
      locked,
      scriptUrl: data.scriptUrl === "" ? null : (data.scriptUrl ?? game.scriptUrl),
      payloadSource: nextPayload,
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
      kind: updated.kind,
      locked: updated.locked,
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
