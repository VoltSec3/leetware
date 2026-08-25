import { requireCsrf, requireRole } from "@/lib/admin-auth";
import { errorResponse, jsonResponse } from "@/lib/http";
import { prisma } from "@/lib/prisma";
import { ensureRuntimeGuard } from "@/lib/runtime-guard";
import { updateGameSchema } from "@/lib/validation";

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

export async function PATCH(request: Request, context: RouteContext) {
  try {
    await requireRole(["ADMIN", "SUPPORT"]);
  } catch {
    return errorResponse("Unauthorized", 401);
  }

  try {
    await requireCsrf(request);
  } catch {
    return errorResponse("Invalid CSRF token", 403);
  }

  const { id } = await context.params;

  let body: unknown;

  try {
    body = await request.json();
  } catch {
    return errorResponse("Invalid JSON body", 400);
  }

  const parsed = updateGameSchema.safeParse(body);

  if (!parsed.success) {
    return errorResponse(
      parsed.error.issues[0]?.message ?? "Invalid request",
      400,
    );
  }

  const data = parsed.data;
  const existing = await prisma.supportedGame.findUnique({ where: { id } });

  if (!existing) {
    return errorResponse("Game not found", 404);
  }

  // Locked entries (boilerplate + the 5 modules) keep their identity.
  if (existing.locked && data.moduleKey && data.moduleKey !== existing.moduleKey) {
    return errorResponse("This entry is locked and cannot be renamed", 403);
  }

  const guardKey = existing.moduleKey || existing.gameId;
  const nextPayload =
    typeof data.payloadSource === "string"
      ? data.payloadSource.length > 0
        ? ensureRuntimeGuard(guardKey, data.payloadSource)
        : null
      : existing.payloadSource;

  const updated = await prisma.supportedGame.update({
    where: { id },
    data: {
      name: data.name ?? existing.name,
      moduleKey: data.moduleKey ?? existing.moduleKey,
      delivery: data.delivery ?? existing.delivery,
      kind: data.kind ?? existing.kind,
      scriptUrl:
        data.scriptUrl === ""
          ? null
          : (data.scriptUrl ?? existing.scriptUrl),
      payloadSource: nextPayload,
      enabled: data.enabled ?? existing.enabled,
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

export async function DELETE(request: Request, context: RouteContext) {
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

  const { id } = await context.params;

  const existing = await prisma.supportedGame.findUnique({ where: { id } });

  if (!existing) {
    return errorResponse("Game not found", 404);
  }

  if (existing.locked) {
    return errorResponse("This entry is locked and cannot be deleted", 403);
  }

  await prisma.supportedGame.delete({ where: { id } });

  return jsonResponse({ success: true });
}
