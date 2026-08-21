import "dotenv/config";

import { prisma } from "../src/lib/prisma";

// Optional convenience seed. Games also self-register automatically the
// first time a loader reports their GameId (see src/lib/game-service.ts),
// so running this is not required.
const games = [
  {
    gameId: "155615604",
    name: "Prison Life",
    moduleKey: "prison-life",
    delivery: "direct",
    scriptUrl:
      "https://raw.githubusercontent.com/VoltSec3/leetware/main/Games/PrisonLife/PrisonLife.luau",
  },
];

async function main() {
  for (const game of games) {
    await prisma.supportedGame.upsert({
      where: { gameId: game.gameId },
      create: {
        ...game,
        autoRegistered: false,
        lastSeenAt: new Date(),
      },
      update: {
        name: game.name,
        moduleKey: game.moduleKey,
        delivery: game.delivery,
        scriptUrl: game.scriptUrl,
        enabled: true,
      },
    });

    console.log(`Seeded game ${game.name} (${game.gameId})`);
  }
}

main()
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
