import { prisma } from "@/lib/prisma";

export type GameDelivery = "direct" | "api";
export type GameKind = "game" | "module";

export type EnsureGameInput = {
  gameId: string;
  name?: string;
  moduleKey?: string;
  scriptUrl?: string;
  delivery?: GameDelivery;
  kind?: GameKind;
};

export const PROTECTED_GAMEOBJECTS = [
  "boilerplate",
  "prison-life",
  "esp",
  "aimbot",
  "chams",
  "tracers",
  "utils",
];

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
 * scriptUrl, payloadSource, enabled) are never overwritten once set -
 * only missing values are filled in and lastSeenAt is bumped.
 */
export async function ensureSupportedGame(input: EnsureGameInput) {
  const gameId = String(input.gameId);
  const kind = input.kind ?? "game";

  // Modules are not tied to a Roblox GameId; their gameId is a stable slug.
  if (kind === "module") {
    if (!/^[a-z0-9][a-z0-9-]{0,63}$/.test(gameId)) {
      return null;
    }
  } else if (!/^\d{1,20}$/.test(gameId)) {
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
        kind,
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

// Enabled, non-fallback games for the public loader catalog. The boilerplate
// entry is intentionally excluded - it is the universal fallback, not a
// PlaceId-keyed game.
export async function listGames() {
  return prisma.supportedGame.findMany({
    where: {
      enabled: true,
      kind: "game",
      moduleKey: { not: "boilerplate" },
    },
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

// Enabled API-delivered modules. Only the module key + name are exposed; the
// payload source is always gated behind an authenticated session.
export async function listModules() {
  return prisma.supportedGame.findMany({
    where: { enabled: true, kind: "module" },
    select: {
      gameId: true,
      name: true,
      moduleKey: true,
      delivery: true,
    },
    orderBy: { name: "asc" },
  });
}

// Idempotently register a protected, API-delivered module. Used by the seed
// script so the 5 built-in modules always exist and cannot be removed.
export async function ensureModule(input: {
  moduleKey: string;
  name: string;
  locked?: boolean;
}) {
  const moduleKey = slugifyModuleKey(input.moduleKey);
  const existing = await prisma.supportedGame.findUnique({
    where: { moduleKey },
  });

  if (existing) {
    return existing;
  }

  return prisma.supportedGame.create({
    data: {
      gameId: moduleKey,
      name: input.name,
      moduleKey,
      delivery: "api",
      kind: "module",
      enabled: true,
      autoRegistered: false,
      locked: input.locked ?? true,
    },
  });
}

export type GameDeliveryInfo = {
  supported: boolean;
  gameId?: string;
  name?: string;
  moduleKey?: string;
  delivery?: GameDelivery;
  scriptUrl?: string | null;
  payload?: string | null;
  kind?: GameKind;
  locked?: boolean;
};

/**
 * Read-only lookup of a registered game. Used by the loader on execute - it
 * MUST never create or mutate a game. Games are created only manually through
 * the admin panel, so an unknown gameId simply returns `supported: false`.
 */
export async function resolveSupportedGame(
  gameId: string | number | undefined | null,
): Promise<GameDeliveryInfo> {
  if (gameId === undefined || gameId === null) {
    return { supported: false };
  }

  const id = String(gameId);

  if (!/^\d{1,20}$/.test(id)) {
    return { supported: false };
  }

  const game = await prisma.supportedGame.findUnique({
    where: { gameId: id },
    select: {
      enabled: true,
      gameId: true,
      name: true,
      moduleKey: true,
      delivery: true,
      scriptUrl: true,
      payloadSource: true,
      kind: true,
      locked: true,
    },
  });

  if (!game || !game.enabled) {
    return { supported: false };
  }

  return {
    supported: true,
    gameId: game.gameId,
    name: game.name,
    moduleKey: game.moduleKey,
    delivery: game.delivery as GameDelivery,
    scriptUrl: game.scriptUrl,
    payload: game.payloadSource,
    kind: game.kind as GameKind,
    locked: game.locked,
  };
}
