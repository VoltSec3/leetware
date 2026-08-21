import { prisma } from "@/lib/prisma";

export type GameDelivery = "direct" | "api";

export type EnsureGameInput = {
  gameId: string;
  name?: string;
  moduleKey?: string;
  scriptUrl?: string;
  delivery?: GameDelivery;
};

export function slugifyModuleKey(name: string): string {
  return (
    name
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-+|-+$/g, "")
      .slice(0, 64) || "unknown-game"
  );
}

/**
 * Autonomously registers or refreshes a game. Called whenever a loader
 * reports its GameId, so new games appear in the dashboard without any
 * manual seeding. Admin-managed fields (name, moduleKey, delivery,
 * scriptUrl, payloadSource, enabled) are never overwritten once set —
 * only missing values are filled in and lastSeenAt is bumped.
 */
export async function ensureSupportedGame(input: EnsureGameInput) {
  const gameId = String(input.gameId);

  if (!/^\d{1,20}$/.test(gameId)) {
    return null;
  }

  const existing = await prisma.supportedGame.findUnique({
    where: { gameId },
  });

  if (existing) {
    return prisma.supportedGame.update({
      where: { id: existing.id },
      data: {
        lastSeenAt: new Date(),
        name: existing.name || input.name || undefined,
        scriptUrl: existing.scriptUrl || input.scriptUrl || undefined,
      },
    });
  }

  const name = input.name?.trim() || `Game ${gameId}`;
  const moduleKey = slugifyModuleKey(input.moduleKey ?? name);

  try {
    return await prisma.supportedGame.create({
      data: {
        gameId,
        name,
        moduleKey,
        delivery: input.delivery ?? "direct",
        scriptUrl: input.scriptUrl,
        enabled: true,
        autoRegistered: true,
        lastSeenAt: new Date(),
      },
    });
  } catch {
    // Lost a race against another concurrent registration; update instead.
    return prisma.supportedGame.update({
      where: { gameId },
      data: { lastSeenAt: new Date() },
    });
  }
}

export async function listEnabledGames() {
  return prisma.supportedGame.findMany({
    where: { enabled: true },
    select: {
      gameId: true,
      name: true,
      moduleKey: true,
      delivery: true,
      scriptUrl: true,
    },
    orderBy: { name: "asc" },
  });
}

/**
 * Best-effort registration from loader-reported context. Never throws so
 * auth flows are never blocked by catalog bookkeeping.
 */
export async function registerGameFromRequest(data: {
  gameId?: string | number;
  gameName?: string;
}) {
  if (data.gameId === undefined || data.gameId === null) {
    return;
  }

  try {
    await ensureSupportedGame({
      gameId: String(data.gameId),
      name: data.gameName,
    });
  } catch {
    // Intentionally ignored.
  }
}
