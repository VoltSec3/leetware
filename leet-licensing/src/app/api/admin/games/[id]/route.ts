import { requireRole, requireCsrf } from "@/lib/admin-auth";
import { errorResponse, jsonResponse } from "@/lib/http";
import { prisma } from "@/lib/prisma";
import { updateGameSchema } from "@/lib/validation";

type RouteContext = {
  params: Promise<{ id: string }>;
};

export async function PATCH(request: Request, context: RouteContext) {
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

  let body: unknown;

  try {
    body = await request.json();
  } catch {
    return errorResponse("Invalid JSON body", 400);
  }

  const parsed = updateGameSchema.safeParse(body);

  if (!parsed.success) {
    return errorResponse(parsed.error.issues[0]?.message ?? "Invalid request", 400);
  }

  const existing = await prisma.supportedGame.findUnique({ where: { id } });

  if (!existing) {
    return errorResponse("Game not found", 404);
  }

  const data = parsed.data;

  if (data.moduleKey && data.moduleKey !== existing.moduleKey) {
    const clash = await prisma.supportedGame.findUnique({
      where: { moduleKey: data.moduleKey },
    });

    if (clash) {
      return errorResponse("moduleKey already in use by another game", 409);
    }
  }

  const updated = await prisma.supportedGame.update({
    where: { id },
    data: {
      name: data.name ?? undefined,
      moduleKey: data.moduleKey ?? undefined,
      delivery: data.delivery ?? undefined,
      scriptUrl:
        data.scriptUrl === ""
          ? null
          : (data.scriptUrl ?? undefined),
      payloadSource:
        data.payloadSource !== undefined
          ? data.payloadSource || null
          : undefined,
      enabled: data.enabled ?? undefined,
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

  await prisma.supportedGame.delete({ where: { id } });

  return jsonResponse({ deleted: true, id });
}
