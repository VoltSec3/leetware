import { Client, Events, GatewayIntentBits } from "discord.js";

import { config } from "./lib/config.js";
import { data as updaterole, execute as updateroleExecute } from "./commands/updaterole.js";
import { fetchRoleState } from "./lib/api.js";
import { applyTierRole } from "./lib/roles.js";

const client = new Client({
  intents: [GatewayIntentBits.Guilds, GatewayIntentBits.GuildMembers],
});

const commands = new Map([[updaterole.name, updateroleExecute]]);

client.once(Events.ClientReady, (ready) => {
  console.log(`logged in as ${ready.user.tag}`);
  console.log(`licensed role id: ${config.licensedRoleId}`);
});

client.on(Events.InteractionCreate, async (interaction) => {
  if (!interaction.isChatInputCommand()) {
    return;
  }

  const command = commands.get(interaction.commandName);

  if (!command) {
    return;
  }

  try {
    await command(interaction);
  } catch (error) {
    console.error(`/${interaction.commandName} failed:`, error);

    const payload = { content: "something went wrong.", ephemeral: true };

    if (interaction.deferred || interaction.replied) {
      await interaction.editReply(payload).catch(() => {});
    } else {
      await interaction.reply(payload).catch(() => {});
    }
  }
});

// best-effort auto-sync: when a member's roles change or they join/leave the
// guild, recompute their licensed role. discord's role add can silently fail
// right after a user joins the guild via oauth - /updaterole is the manual fix.
async function syncMember(member) {
  if (!member || member.user?.bot) {
    return;
  }

  try {
    const state = await fetchRoleState(member.id);
    const tier = state.shouldHaveRole ? state.tier ?? "standard" : null;
    const change = await applyTierRole(member, tier);

    if (change !== "unchanged") {
      console.log(
        `${member.user.tag}: ${tier ? `synced to ${tier}` : "removed"} role (${state.reason})`,
      );
    }
  } catch (error) {
    console.error(`sync failed for ${member.user?.tag}:`, error.message);
  }
}

client.on(Events.GuildMemberAdd, syncMember);

client.on(Events.GuildMemberUpdate, async (oldMember, newMember) => {
  // only resync when something other than the licensed role itself changed
  const before = oldMember.roles.cache.has(config.licensedRoleId);
  const after = newMember.roles.cache.has(config.licensedRoleId);

  if (before === after) {
    return;
  }

  try {
    const state = await fetchRoleState(newMember.id);

    // an admin manually granted the role but the site says no - leave it alone
    // for 30 minutes by not fighting manual changes; /updaterole is authoritative
    if (after && !before && !state.shouldHaveRole && !state.banned) {
      console.log(`${newMember.user.tag}: role added manually while eligible`);
    }
  } catch {
    // ignore
  }
});

process.on("SIGINT", () => {
  client.destroy();
  process.exit(0);
});

client.login(config.botToken);
