import { Client, Events, GatewayIntentBits, MessageFlags } from "discord.js";

import { config } from "./lib/config.js";
import { data as updaterole, execute as updateroleExecute } from "./commands/updaterole.js";
import {
  data as giveaway,
  execute as giveawayExecute,
} from "./commands/giveaway.js";
import {
  buildEmbed,
  checkRequirements,
  endGiveaway,
} from "./lib/giveaway.js";
import { fetchExpiredDiscords, fetchRoleState } from "./lib/api.js";
import { applyTierRole } from "./lib/roles.js";
import { getGiveaway, listActive, saveGiveaway } from "./lib/store.js";

const client = new Client({
  intents: [GatewayIntentBits.Guilds, GatewayIntentBits.GuildMembers],
});

const commands = new Map([
  [updaterole.name, updateroleExecute],
  [giveaway.name, giveawayExecute],
]);

client.once(Events.ClientReady, (ready) => {
  console.log(`logged in as ${ready.user.tag}`);
  console.log(`licensed role id: ${config.licensedRoleId}`);
});

client.on(Events.InteractionCreate, async (interaction) => {
  if (interaction.isChatInputCommand()) {
    const command = commands.get(interaction.commandName);

    if (!command) {
      return;
    }

    try {
      await command(interaction);
    } catch (error) {
      console.error(`/${interaction.commandName} failed:`, error);

      const payload = { content: "something went wrong.", flags: [MessageFlags.Ephemeral] };

      if (interaction.deferred || interaction.replied) {
        await interaction.editReply(payload).catch(() => {});
      } else {
        await interaction.reply(payload).catch(() => {});
      }
    }

    return;
  }

  if (interaction.isButton()) {
    if (interaction.customId.startsWith("giveaway_enter:")) {
      const id = interaction.customId.slice("giveaway_enter:".length);
      await handleGiveawayEnter(interaction, id);
    }
  }
});

async function handleGiveawayEnter(interaction, id) {
  const g = getGiveaway(id);

  if (!g) {
    await interaction.reply({
      content: "this giveaway no longer exists.",
      flags: [MessageFlags.Ephemeral],
    });
    return;
  }

  if (g.status !== "active") {
    await interaction.reply({
      content: "this giveaway is not active.",
      flags: [MessageFlags.Ephemeral],
    });
    return;
  }

  if (g.paused) {
    await interaction.reply({
      content: "this giveaway is paused.",
      flags: [MessageFlags.Ephemeral],
    });
    return;
  }

  const member = interaction.member;

  if (!member || typeof member.roles === "undefined") {
    await interaction.reply({
      content: "could not verify your account.",
      flags: [MessageFlags.Ephemeral],
    });
    return;
  }

  const check = await checkRequirements(g, member);

  if (!check.ok) {
    await interaction.reply({ content: check.reason, flags: [MessageFlags.Ephemeral] });
    return;
  }

  if (g.entries.includes(interaction.user.id)) {
    await interaction.reply({
      content: "you have already entered this giveaway.",
      flags: [MessageFlags.Ephemeral],
    });
    return;
  }

  g.entries.push(interaction.user.id);
  saveGiveaway(g);

  try {
    await interaction.message.edit({ embeds: [buildEmbed(g)] });
  } catch {
    // message may have been removed; ignore
  }

  await interaction.reply({
    content: "you entered the giveaway!",
    flags: [MessageFlags.Ephemeral],
  });
}

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

// Periodically end giveaways whose duration has elapsed.
async function autoEndLoop() {
  for (const g of listActive()) {
    if (g.status === "active" && !g.paused && Date.now() >= g.endsAt) {
      try {
        await endGiveaway(client, g);
        console.log(`auto-ended giveaway ${g.id}`);
      } catch (error) {
        console.error(`auto-end failed for ${g.id}:`, error);
      }
    }
  }
}

// Periodically strip the licensed role from users whose license expired.
async function expiredRoleLoop() {
  try {
    const discordIds = await fetchExpiredDiscords();
    const guild = config.guildId
      ? client.guilds.cache.get(config.guildId)
      : client.guilds.cache.first();

    if (!guild) {
      return;
    }

    for (const discordId of discordIds) {
      try {
        const member = await guild.members.fetch(discordId);
        const change = await applyTierRole(member, null);
        if (change !== "unchanged") {
          console.log(`removed licensed role from expired user ${discordId}`);
        }
      } catch (error) {
        console.error(`expired role removal failed for ${discordId}:`, error);
      }
    }
  } catch (error) {
    console.error("expired role loop failed:", error);
  }
}

setInterval(autoEndLoop, 30_000);
setInterval(expiredRoleLoop, 5 * 60 * 1000);

client.login(config.botToken);
