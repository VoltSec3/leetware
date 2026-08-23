import { REST, Routes } from "discord.js";

import { config } from "./lib/config.js";
import { data as updaterole } from "./commands/updaterole.js";

const commands = [updaterole.toJSON()].map((command) => command);

const rest = new REST().setToken(config.botToken);

try {
  const route = config.guildId
    ? Routes.applicationGuildCommands(config.clientId, config.guildId)
    : Routes.applicationCommands(config.clientId);

  console.log(`deploying ${commands.length} slash command(s)...`);

  await rest.put(route, { body: commands });

  console.log("done.");
} catch (error) {
  console.error("deploy failed:", error);
}
