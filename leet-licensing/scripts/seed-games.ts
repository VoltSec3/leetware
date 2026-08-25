import "dotenv/config";

import { readFileSync } from "node:fs";
import { join } from "node:path";

import { prisma } from "../src/lib/prisma";
import { ensureModule, PROTECTED_GAMEOBJECTS } from "../src/lib/game-service";
import { ensureRuntimeGuard } from "../src/lib/runtime-guard";

const REPO_ROOT = join(__dirname, "..", "..");

function readSource(relativePath: string): string | null {
  try {
    return readFileSync(join(REPO_ROOT, relativePath), "utf8");
  } catch {
    return null;
  }
}

// Games that also self-register automatically the first time a loader reports
// their GameId, so running this seed is not strictly required.
const games = [
  {
    gameId: "155615604",
    name: "Prison Life",
    moduleKey: "prison-life",
    delivery: "api",
    sourcePath: "Games/PrisonLife/PrisonLife.luau",
  },
];

// Protected, hard-coded entries. These are API-delivered, editable, but can
// never be deleted (or renamed). The boilerplate is the universal fallback
// game; the five modules are shared features pulled by the loader.
const protectedEntries = [
  {
    gameId: "boilerplate",
    name: "Universal Boilerplate",
    moduleKey: "boilerplate",
    kind: "game" as const,
    delivery: "api" as const,
    sourcePath: "Boilerplate.luau",
  },
  {
    gameId: "esp",
    name: "ESP",
    moduleKey: "esp",
    kind: "module" as const,
    delivery: "api" as const,
    sourcePath: "Modules/ESP.luau",
  },
  {
    gameId: "aimbot",
    name: "Aimbot",
    moduleKey: "aimbot",
    kind: "module" as const,
    delivery: "api" as const,
    sourcePath: "Modules/Aimbot.luau",
  },
  {
    gameId: "chams",
    name: "Chams",
    moduleKey: "chams",
    kind: "module" as const,
    delivery: "api" as const,
    sourcePath: "Modules/Chams.luau",
  },
  {
    gameId: "tracers",
    name: "Tracers",
    moduleKey: "tracers",
    kind: "module" as const,
    delivery: "api" as const,
    sourcePath: "Modules/Tracers.luau",
  },
  {
    gameId: "utils",
    name: "Utils",
    moduleKey: "utils",
    kind: "module" as const,
    delivery: "api" as const,
    sourcePath: "Modules/Utils.luau",
  },
];

  async function main() {
    for (const game of games) {
      const raw = readSource(game.sourcePath);
      const source = raw ? ensureRuntimeGuard(game.moduleKey, raw) : raw;

      await prisma.supportedGame.upsert({
      where: { gameId: game.gameId },
      create: {
        gameId: game.gameId,
        name: game.name,
        moduleKey: game.moduleKey,
        delivery: game.delivery,
        kind: "game",
        enabled: true,
        autoRegistered: false,
        payloadSource: source,
        lastSeenAt: new Date(),
      },
      update: {
        name: game.name,
        moduleKey: game.moduleKey,
        delivery: game.delivery,
        enabled: true,
        payloadSource: source ?? undefined,
      },
    });

    console.log(`Seeded game ${game.name} (${game.gameId})`);
  }

  for (const entry of protectedEntries) {
    const raw = readSource(entry.sourcePath);
    const source = raw ? ensureRuntimeGuard(entry.moduleKey, raw) : raw;

    await prisma.supportedGame.upsert({
      where: { gameId: entry.gameId },
      create: {
        gameId: entry.gameId,
        name: entry.name,
        moduleKey: entry.moduleKey,
        delivery: entry.delivery,
        kind: entry.kind,
        locked: true,
        enabled: true,
        autoRegistered: false,
        payloadSource: source,
        lastSeenAt: new Date(),
      },
      update: {
        name: entry.name,
        delivery: entry.delivery,
        kind: entry.kind,
        locked: true,
        enabled: true,
        payloadSource: source ?? undefined,
      },
    });

    console.log(`Seeded protected ${entry.kind} ${entry.name} (${entry.moduleKey})`);
  }

  // Make sure the shared module helper knows about the five built-ins.
  for (const key of ["esp", "aimbot", "chams", "tracers", "utils"]) {
    await ensureModule({ moduleKey: key, name: key.toUpperCase(), locked: true });
  }

  void PROTECTED_GAMEOBJECTS;
}

main()
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
